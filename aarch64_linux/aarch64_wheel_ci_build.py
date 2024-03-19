#!/usr/bin/env python3
# encoding: UTF-8

import os
from subprocess import check_output, check_call
from pygit2 import Repository
from typing import List


def list_dir(path: str) -> List[str]:
    ''''
    Helper for getting paths for Python
    '''
    return check_output(["ls", "-1", path]).decode().split("\n")


def build_ArmComputeLibrary(git_clone_flags: str = "") -> None:
    '''
    Using ArmComputeLibrary for aarch64 PyTorch
    '''
    print('Building Arm Compute Library')
    acl_build_flags=" ".join(["debug=0", "neon=1", "opencl=0", "os=linux", "openmp=1", "cppthreads=0",
                              "arch=armv8a", "multi_isa=1", "fixed_format_kernels=1", "build=native"])
    os.system("cd / && mkdir /acl")
    os.system(f"git clone https://github.com/ARM-software/ComputeLibrary.git -b v23.08 {git_clone_flags}")
    os.system("cd ComputeLibrary; export acl_install_dir=/acl; "
              f"scons Werror=1 -j8 {acl_build_flags} build_dir=$acl_install_dir/build; "
              "cp -r arm_compute $acl_install_dir; "
              "cp -r include $acl_install_dir; "
              "cp -r utils $acl_install_dir; "
              "cp -r support $acl_install_dir; "
              "cp -r src $acl_install_dir; cd /")


def complete_wheel(folder: str) -> str:
    '''
    Complete wheel build and put in artifact location
    '''
    wheel_name = list_dir(f"/{folder}/dist")[0]

    if "pytorch" in folder:
        print("Repairing Wheel with AuditWheel")
        os.system(f"cd /{folder}; auditwheel repair dist/{wheel_name}")
        repaired_wheel_name = list_dir(f"/{folder}/wheelhouse")[0]

        print(f"Moving {repaired_wheel_name} wheel to /{folder}/dist")
        os.system(f"mv /{folder}/wheelhouse/{repaired_wheel_name} /{folder}/dist/")
    else:
        repaired_wheel_name = wheel_name

    print(f"Copying {repaired_wheel_name} to artfacts")
    os.system(f"mv /{folder}/dist/{repaired_wheel_name} /artifacts/")

    return repaired_wheel_name


def parse_arguments():
    '''
    Parse inline arguments
    '''
    from argparse import ArgumentParser
    parser = ArgumentParser("AARCH64 wheels python CD")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--build-only", action="store_true")
    parser.add_argument("--test-only", type=str)
    parser.add_argument("--enable-mkldnn", action="store_true")
    return parser.parse_args()


if __name__ == '__main__':
    '''
    Entry Point
    '''
    args = parse_arguments()
    enable_mkldnn = args.enable_mkldnn
    repo = Repository('/pytorch')
    branch = repo.head.name
    if branch == 'HEAD':
        branch = 'master'

    git_clone_flags = " --depth 1 --shallow-submodules"

    print('Building PyTorch wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    os.system("python setup.py clean")

    override_package_version = os.getenv("OVERRIDE_PACKAGE_VERSION")
    if override_package_version is not None:
        version = override_package_version
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={version} PYTORCH_BUILD_NUMBER=1 "
    elif branch in ['nightly', 'master']:
        build_date = check_output(['git', 'log', '--pretty=format:%cs', '-1'], cwd='/pytorch').decode().replace('-', '')
        version = check_output(['cat', 'version.txt'], cwd='/pytorch').decode().strip()[:-2]
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={version}.dev{build_date} PYTORCH_BUILD_NUMBER=1 "
    elif branch.startswith(("v1.", "v2.")):
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={branch[1:branch.find('-')]} PYTORCH_BUILD_NUMBER=1 "

    if enable_mkldnn:
        build_ArmComputeLibrary(git_clone_flags)
        print("build pytorch with mkldnn+acl backend")
        build_vars += "USE_MKLDNN=ON USE_MKLDNN_ACL=ON " \
                      "ACL_ROOT_DIR=/acl " \
                      "LD_LIBRARY_PATH=/pytorch/build/lib:/acl/build:$LD_LIBRARY_PATH " \
                      "ACL_INCLUDE_DIR=/acl/build " \
                      "ACL_LIBRARY=/acl/build "
    else:
        print("build pytorch without mkldnn backend")

    # patch mkldnn to fix aarch64 mac and aws lambda crash
    print("Applying mkl-dnn patch to fix crash due to /sys not accesible")
    with open("/builder/mkldnn_fix/fix-xbyak-failure.patch") as f:
        check_call(["patch", "-p1"], stdin=f, cwd="/pytorch/third_party/ideep/mkl-dnn")

    # Apply patch for https://github.com/pytorch/pytorch/issues/120547
    with open("/builder/mkldnn_fix/brdgmm.patch") as f:
        check_call(["patch", "-p1"], stdin=f, cwd="/pytorch/third_party/ideep/mkl-dnn")

    os.system(f"cd /pytorch; {build_vars} python3 setup.py bdist_wheel")
    pytorch_wheel_name = complete_wheel("pytorch")
    print(f"Build Compelete. Created {pytorch_wheel_name}..")
