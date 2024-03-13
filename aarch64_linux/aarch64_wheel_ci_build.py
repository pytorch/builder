#!/usr/bin/env python3
# encoding: UTF-8

import os
import shutil
from subprocess import check_output, check_call
from pygit2 import Repository
from typing import List


def list_dir(path: str) -> List[str]:
    """'
    Helper for getting paths for Python
    """
    return check_output(["ls", "-1", path]).decode().split("\n")


def build_ArmComputeLibrary() -> None:
    """
    Using ArmComputeLibrary for aarch64 PyTorch
    """
    print("Building Arm Compute Library")
    acl_build_flags = [
        "debug=0",
        "neon=1",
        "opencl=0",
        "os=linux",
        "openmp=1",
        "cppthreads=0",
        "arch=armv8a",
        "multi_isa=1",
        "fixed_format_kernels=1",
        "build=native",
    ]
    acl_install_dir = "/acl"
    acl_checkout_dir = "ComputeLibrary"
    os.makedirs(acl_install_dir)
    check_call(
        [
            "git",
            "clone",
            "https://github.com/ARM-software/ComputeLibrary.git",
            "-b",
            "v23.08",
            "--depth",
            "1",
            "--shallow-submodules",
        ]
    )
    check_call(
        ["scons", "Werror=1", "-j8", f"build_dir=/{acl_install_dir}/build"]
        + acl_build_flags,
        cwd=acl_checkout_dir,
    )
    for d in ["arm_compute", "include", "utils", "support", "src"]:
        shutil.copytree(f"{acl_checkout_dir}/{d}", f"{acl_install_dir}/{d}")


def complete_wheel(folder: str) -> str:
    """
    Complete wheel build and put in artifact location
    """
    wheel_name = list_dir(f"/{folder}/dist")[0]

    if "pytorch" in folder:
        print("Repairing Wheel with AuditWheel")
        check_call(["auditwheel", "repair", f"dist/{wheel_name}"], cwd=folder)
        repaired_wheel_name = list_dir(f"/{folder}/wheelhouse")[0]

        print(f"Moving {repaired_wheel_name} wheel to /{folder}/dist")
        os.rename(
            f"/{folder}/wheelhouse/{repaired_wheel_name}",
            f"/{folder}/dist/{repaired_wheel_name}",
        )
    else:
        repaired_wheel_name = wheel_name

    print(f"Copying {repaired_wheel_name} to artfacts")
    shutil.copy2(
        f"/{folder}/dist/{repaired_wheel_name}", f"/artifacts/{repaired_wheel_name}"
    )

    return repaired_wheel_name


def update_wheel(wheel_path):
    folder = os.path.dirname(wheel_path)
    filename = os.path.basename(wheel_path)
    os.mkdir(f"{folder}/tmp")
    os.system(f"unzip {wheel_path} -d {folder}/tmp")
    libs_to_copy = [
        "/usr/local/cuda/lib64/libcudnn.so.8",
        "/usr/local/cuda/lib64/libcublas.so.11",
        "/usr/local/cuda/lib64/libcublasLt.so.11",
        "/usr/local/cuda/lib64/libcudart.so.11.0",
        "/usr/local/cuda/lib64/libnvToolsExt.so.1",
        "/usr/local/cuda/lib64/libnvrtc.so.11.2",
        "/usr/local/cuda/lib64/libnvrtc-builtins.so.11.8",
        "/opt/conda/lib/libgfortran.so.5",
        "/opt/conda/lib/libopenblas.so.0",
        "/opt/conda/lib/libgomp.so.1",
    ]
    # Copy libraries to unzipped_folder/a/lib
    for lib_path in libs_to_copy:
        lib_name = os.path.basename(lib_path)
        shutil.copy2(lib_path, f"{folder}/tmp/torch/lib/{lib_name}")
    os.system(
        f"cd {folder}/tmp/torch/lib/; patchelf --set-rpath '$ORIGIN' {folder}/tmp/torch/lib/libtorch_cuda.so"
    )
    os.mkdir(f"{folder}/new_wheel")
    os.system(f"cd {folder}/tmp/; zip -r {folder}/new_wheel/{filename} *")
    os.system(f"rm -rf {folder}/tmp")


def parse_arguments():
    """
    Parse inline arguments
    """
    from argparse import ArgumentParser

    parser = ArgumentParser("AARCH64 wheels python CD")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--build-only", action="store_true")
    parser.add_argument("--test-only", type=str)
    parser.add_argument("--enable-mkldnn", action="store_true")
    parser.add_argument("--enable-cuda", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    """
    Entry Point
    """
    args = parse_arguments()
    enable_mkldnn = args.enable_mkldnn
    enable_cuda = args.enable_cuda
    repo = Repository("/pytorch")
    branch = repo.head.name
    if branch == "HEAD":
        branch = "master"

    print("Building PyTorch wheel")
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    os.system("python setup.py clean")

    override_package_version = os.getenv("OVERRIDE_PACKAGE_VERSION")
    if override_package_version is not None:
        version = override_package_version
        build_vars += (
            f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={version} PYTORCH_BUILD_NUMBER=1 "
        )
    elif branch in ["nightly", "master"]:
        build_date = (
            check_output(["git", "log", "--pretty=format:%cs", "-1"], cwd="/pytorch")
            .decode()
            .replace("-", "")
        )
        version = (
            check_output(["cat", "version.txt"], cwd="/pytorch").decode().strip()[:-2]
        )
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={version}.dev{build_date} PYTORCH_BUILD_NUMBER=1 "
    elif branch.startswith(("v1.", "v2.")):
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={branch[1:branch.find('-')]} PYTORCH_BUILD_NUMBER=1 "

    if enable_mkldnn:
        build_ArmComputeLibrary()
        print("build pytorch with mkldnn+acl backend")
        build_vars += (
            "USE_MKLDNN=ON USE_MKLDNN_ACL=ON "
            "ACL_ROOT_DIR=/acl "
            "LD_LIBRARY_PATH=/pytorch/build/lib:/acl/build:$LD_LIBRARY_PATH "
            "ACL_INCLUDE_DIR=/acl/build "
            "ACL_LIBRARY=/acl/build "
        )
    else:
        print("build pytorch without mkldnn backend")

    # patch mkldnn to fix aarch64 mac and aws lambda crash
    print("Applying mkl-dnn patch to fix crash due to /sys not accesible")
    with open("/builder/mkldnn_fix/fix-xbyak-failure.patch") as f:
        check_call(["patch", "-p1"], stdin=f, cwd="/pytorch/third_party/ideep/mkl-dnn")

    if enable_cuda:
        build_vars += (
            "TORCH_NVCC_FLAGS='-Xfatbin -compress-all --threads 2' USE_STATIC_CUDNN=0 "
            "NCCL_ROOT_DIR=/usr/local/cuda TH_BINARY_BUILD=1 USE_STATIC_NCCL=1 ATEN_STATIC_CUDA=1 "
            "USE_CUDA_STATIC_LINK=1 INSTALL_TEST=0 USE_CUPTI_SO=0 "
            "EXTRA_CAFFE2_CMAKE_FLAGS='-DATEN_NO_TEST=ON' "
        )

    print("Applying mkl-dnn patch to improve torch.compile() perf")
    os.system("cd /pytorch/third_party/ideep/mkl-dnn && patch -p1 < /builder/mkldnn_fix/onednn-pr1768-aarch64-add-acl-sbgemm-inner-product-primitive.patch")  # noqa: E501

    os.system(f"cd /pytorch; {build_vars} python3 setup.py bdist_wheel")
    pytorch_wheel_name = complete_wheel("pytorch")
    print(f"Build Compelete. Created {pytorch_wheel_name}..")
    print("Update the cuda dependency.")
    if enable_cuda:
        filename = os.listdir("/pytorch/dist/")
        wheel_path = f"/pytorch/dist/{filename[0]}"
        update_wheel(wheel_path)
