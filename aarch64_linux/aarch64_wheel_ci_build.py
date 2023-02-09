#!/usr/bin/env python3

import os
import subprocess
from typing import Dict, List, Optional, Tuple


''''
Helper for getting paths for Python
'''
def list_dir(path: str) -> List[str]:
     return subprocess.check_output(["ls", "-1", path]).decode().split("\n")


'''
Helper to get repo branches for specific versions
'''
def checkout_repo(branch: str = "main",
                  url: str = "",
                  git_clone_flags: str = "",
                  mapping: Dict[str, Tuple[str, str]] = []) -> Optional[str]:
    for prefix in mapping:
        if not branch.startswith(prefix):
            continue
        tag = f"v{mapping[prefix][0]}-{mapping[prefix][1]}"
        os.system(f"git clone {url} -b {tag} {git_clone_flags}")
        return mapping[prefix][0]

    os.system(f"git clone {url} {git_clone_flags}")
    return None


'''
Using OpenBLAS with PyTorch
'''
def build_OpenBLAS(git_clone_flags: str = "") -> None:
    print('Building OpenBLAS')
    os.system(f"cd /; git clone https://github.com/xianyi/OpenBLAS -b v0.3.21 {git_clone_flags}")
    make_flags = "NUM_THREADS=64 USE_OPENMP=1 NO_SHARED=1 DYNAMIC_ARCH=1 TARGET=ARMV8 "
    os.system(f"cd OpenBLAS; make {make_flags} -j8; make {make_flags} install; cd /; rm -rf OpenBLAS")


'''
Using ArmComputeLibrary for aarch64 PyTorch
'''
def build_ArmComputeLibrary(git_clone_flags: str = "") -> None:
    print('Building Arm Compute Library')
    os.system("cd / && mkdir /acl")
    os.system(f"git clone https://github.com/ARM-software/ComputeLibrary.git -b v22.11 {git_clone_flags}")
    os.system(f"cd ComputeLibrary; export acl_install_dir=/acl; " \
                f"scons Werror=1 -j8 debug=0 neon=1 opencl=0 os=linux openmp=1 cppthreads=0 arch=armv8.2-a multi_isa=1 build=native build_dir=$acl_install_dir/build; " \
                f"cp -r arm_compute $acl_install_dir; " \
                f"cp -r include $acl_install_dir; " \
                f"cp -r utils $acl_install_dir; " \
                f"cp -r support $acl_install_dir; " \
                f"cp -r src $acl_install_dir; cd /")


'''
Script to embed libgomp to the wheels
'''
def embed_libgomp(wheel_name) -> None:
    print('Embedding libgomp into wheel')
    os.system(f"python3 /builder/aarch64_linux/embed_library.py {wheel_name} --update-tag")


'''
Build TorchVision wheel
'''
def build_torchvision(branch: str = "main",
                      git_clone_flags: str = "") -> str:
    print('Checking out TorchVision repo')
    build_version = checkout_repo(branch=branch,
                                  url="https://github.com/pytorch/vision",
                                  git_clone_flags=git_clone_flags,
                                  mapping={
                                      "v1.7.1": ("0.8.2", "rc2"),
                                      "v1.8.0": ("0.9.0", "rc3"),
                                      "v1.8.1": ("0.9.1", "rc1"),
                                      "v1.9.0": ("0.10.0", "rc1"),
                                      "v1.10.0": ("0.11.1", "rc1"),
                                      "v1.10.1": ("0.11.2", "rc1"),
                                      "v1.10.2": ("0.11.3", "rc1"),
                                      "v1.11.0": ("0.12.0", "rc1"),
                                      "v1.12.0": ("0.13.0", "rc4"),
                                      "v1.12.1": ("0.13.1", "rc6"),
                                      "v1.13.0": ("0.14.0", "rc4"),
                                      "v1.13.1": ("0.14.1", "rc2"),
                                  })
    print('Building TorchVision wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    if branch == 'nightly':
        version = ''
        if os.path.exists('/vision/version.txt'):
            version = subprocess.check_output(['cat', '/vision/version.txt']).decode().strip()
        if len(version) == 0:
            # In older revisions, version was embedded in setup.py
            version = subprocess.check_output(['grep', 'version', 'setup.py']).decode().strip().split('\'')[1][:-2]
        build_date = subprocess.check_output(['git','log','--pretty=format:%cs','-1'], cwd='/vision').decode().replace('-','')
        build_vars += f"BUILD_VERSION={version}.dev{build_date}"
    elif build_version is not None:
        build_vars += f"BUILD_VERSION={build_version}"

    os.system(f"cd /vision; {build_vars} python3 setup.py bdist_wheel")
    wheel_name = list_dir("/vision/dist")[0]
    embed_libgomp(f"/vision/dist/{wheel_name}")

    print('Move TorchVision wheel to artfacts')
    os.system(f"mv /vision/dist/{wheel_name} /artifacts/")
    return wheel_name


'''
Build TorchAudio wheel
'''
def build_torchaudio(branch: str = "main",
                     git_clone_flags: str = "") -> str:
    print('Checking out TorchAudio repo')
    git_clone_flags += " --recurse-submodules"
    build_version = checkout_repo(branch=branch,
                                  url="https://github.com/pytorch/audio",
                                  git_clone_flags=git_clone_flags,
                                  mapping={
                                      "v1.9.0": ("0.9.0", "rc2"),
                                      "v1.10.0": ("0.10.0", "rc5"),
                                      "v1.10.1": ("0.10.1", "rc1"),
                                      "v1.10.2": ("0.10.2", "rc1"),
                                      "v1.11.0": ("0.11.0", "rc1"),
                                      "v1.12.0": ("0.12.0", "rc3"),
                                      "v1.12.1": ("0.12.1", "rc5"),
                                      "v1.13.0": ("0.13.0", "rc4"),
                                      "v1.13.1": ("0.13.1", "rc2"),
                                  })
    print('Building TorchAudio wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    if branch == 'nightly':
        version = ''
        if os.path.exists('/audio/version.txt'):
            version = subprocess.check_output(['cat', '/audio/version.txt']).decode().strip()
        build_date = subprocess.check_output(['git','log','--pretty=format:%cs','-1'], cwd='/audio').decode().replace('-','')
        build_vars += f"BUILD_VERSION={version}.dev{build_date}"
    elif build_version is not None:
        build_vars += f"BUILD_VERSION={build_version}"

    os.system(f"cd /audio; {build_vars} python3 setup.py bdist_wheel")
    wheel_name = list_dir("/audio/dist")[0]
    embed_libgomp(f"/audio/dist/{wheel_name}")

    print('Move TorchAudio wheel to artfacts')
    os.system(f"mv /audio/dist/{wheel_name} /artifacts/")
    return wheel_name


'''
Build TorchText wheel
'''
def build_torchtext(branch: str = "main",
                    git_clone_flags: str = "") -> str:
    print('Checking out TorchText repo')
    os.system(f"cd /")
    git_clone_flags += " --recurse-submodules"
    build_version = checkout_repo(branch=branch,
                                  url="https://github.com/pytorch/text",
                                  git_clone_flags=git_clone_flags,
                                  mapping={
                                      "v1.9.0": ("0.10.0", "rc1"),
                                      "v1.10.0": ("0.11.0", "rc2"),
                                      "v1.10.1": ("0.11.1", "rc1"),
                                      "v1.10.2": ("0.11.2", "rc1"),
                                      "v1.11.0": ("0.12.0", "rc1"),
                                      "v1.12.0": ("0.13.0", "rc2"),
                                      "v1.12.1": ("0.13.1", "rc5"),
                                      "v1.13.0": ("0.14.0", "rc3"),
                                      "v1.13.1": ("0.14.1", "rc1"),
                                  })
    print('Building TorchText wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    if branch == 'nightly':
        version = ''
        if os.path.exists('/text/version.txt'):
            version = subprocess.check_output(['cat', '/text/version.txt']).decode().strip()
        build_date = subprocess.check_output(['git','log','--pretty=format:%cs','-1'], cwd='/text').decode().replace('-','')
        build_vars += f"BUILD_VERSION={version}.dev{build_date}"
    elif build_version is not None:
        build_vars += f"BUILD_VERSION={build_version}"

    os.system(f"cd text; {build_vars} python3 setup.py bdist_wheel")
    wheel_name = list_dir("/text/dist")[0]
    embed_libgomp(f"/text/dist/{wheel_name}")

    print('Move TorchText wheel to artfacts')
    os.system(f"mv /text/dist/{wheel_name} /artifacts/")
    return wheel_name


'''
Build TorchData wheel
'''
def build_torchdata(branch: str = "main",
                     git_clone_flags: str = "") -> str:
    print('Checking out TorchData repo')
    git_clone_flags += " --recurse-submodules"
    build_version = checkout_repo(branch=branch,
                                  url="https://github.com/pytorch/data",
                                  git_clone_flags=git_clone_flags,
                                  mapping={
                                      "v1.11.0": ("0.3.0", "rc1"),
                                      "v1.12.0": ("0.4.0", "rc3"),
                                      "v1.12.1": ("0.4.1", "rc5"),
                                      "v1.13.1": ("0.5.1", "rc2"),
                                  })
    print('Building TorchData wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    if branch == 'nightly':
        version = ''
        if os.path.exists('/data/version.txt'):
            version = subprocess.check_output(['cat', '/data/version.txt']).decode().strip()
        build_date = subprocess.check_output(['git','log','--pretty=format:%cs','-1'], cwd='/data').decode().replace('-','')
        build_vars += f"BUILD_VERSION={version}.dev{build_date}"
    elif build_version is not None:
        build_vars += f"BUILD_VERSION={build_version}"

    os.system(f"cd /data; {build_vars} python3 setup.py bdist_wheel")
    wheel_name = list_dir("/data/dist")[0]
    embed_libgomp(f"/data/dist/{wheel_name}")

    print('Move TorchAudio wheel to artfacts')
    os.system(f"mv /data/dist/{wheel_name} /artifacts/")
    return wheel_name


def parse_arguments():
    from argparse import ArgumentParser
    parser = ArgumentParser("AARCH64 wheels python CD")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--build-only", action="store_true")
    parser.add_argument("--test-only", type=str)
    parser.add_argument("--python-version", type=str, choices=['3.6', '3.7', '3.8', '3.9', '3.10'], default=None)
    parser.add_argument("--branch", type=str, default="master")
    parser.add_argument("--compiler", type=str, choices=['gcc-7', 'gcc-8', 'gcc-9', 'clang'], default="gcc-8")
    parser.add_argument("--enable-mkldnn", action="store_true")
    return parser.parse_args()


'''
Entry Point
'''
if __name__ == '__main__':

    args = parse_arguments()
    branch = args.branch
    enable_mkldnn = args.enable_mkldnn

    git_clone_flags = " --depth 1 --shallow-submodules"
    os.system(f"conda install -y ninja scons")

    print("Build and Install OpenBLAS")
    build_OpenBLAS(git_clone_flags)

    print('Building PyTorch wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    os.system(f"cd /pytorch; pip install -r requirements.txt")
    os.system(f"pip install auditwheel")
    os.system(f"python setup.py clean")

    if branch == 'nightly' or branch == 'master':
        build_date = subprocess.check_output(['git','log','--pretty=format:%cs','-1'], cwd='/pytorch').decode().replace('-','')
        version = subprocess.check_output(['cat','version.txt'], cwd='/pytorch').decode().strip()[:-2]
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={version}.dev{build_date} PYTORCH_BUILD_NUMBER=1"
    if branch.startswith("v1.") or branch.startswith("v2."):
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={branch[1:branch.find('-')]} PYTORCH_BUILD_NUMBER=1"
    if enable_mkldnn:
        build_ArmComputeLibrary(git_clone_flags)
        print("build pytorch with mkldnn+acl backend")
        os.system(f"export ACL_ROOT_DIR=/acl; export LD_LIBRARY_PATH=/acl/build; export ACL_LIBRARY=/acl/build")
        build_vars += " USE_MKLDNN=ON USE_MKLDNN_ACL=ON"
        os.system(f"cd /pytorch; {build_vars} python3 setup.py bdist_wheel")
        print('Repair the wheel')
        pytorch_wheel_name = list_dir("pytorch/dist")[0]
        os.system(f"export LD_LIBRARY_PATH=/pytorch/build/lib:$LD_LIBRARY_PATH; auditwheel repair /pytorch/dist/{pytorch_wheel_name}")
        print('replace the original wheel with the repaired one')
        pytorch_repaired_wheel_name = list_dir("wheelhouse")[0]
        os.system(f"cp /wheelhouse/{pytorch_repaired_wheel_name} /pytorch/dist/{pytorch_wheel_name}")
    else:
        print("build pytorch without mkldnn backend")
        os.system(f"cd pytorch ; {build_vars} python3 setup.py bdist_wheel")

    print("Deleting build folder")
    os.system("cd /pytorch; rm -rf build")
    pytorch_wheel_name = list_dir("/pytorch/dist")[0]
    embed_libgomp(f"/pytorch/dist/{pytorch_wheel_name}")
    print('Move PyTorch wheel to artfacts')
    os.system(f"mv /pytorch/dist/{pytorch_wheel_name} /artifacts/")
    print("Installing Pytorch wheel")
    os.system(f"pip install /artifacts/{pytorch_wheel_name}")
    
    vision_wheel_name = build_torchvision(branch=branch, git_clone_flags=git_clone_flags)
    audio_wheel_name = build_torchaudio(branch=branch, git_clone_flags=git_clone_flags)
    text_wheel_name = build_torchtext(branch=branch, git_clone_flags=git_clone_flags)
    data_wheel_name = build_torchdata(branch=branch, git_clone_flags=git_clone_flags)

    print(f"Wheels Created:\n" \
            f"{pytorch_wheel_name}\n" \
            f"{vision_wheel_name}\n" \
            f"{audio_wheel_name}\n" \
            f"{text_wheel_name}\n" \
            f"{data_wheel_name}\n")
