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


def build_OpenBLAS() -> None:
    '''
    Building OpenBLAS, because the package in many linux is old
    '''
    print('Building OpenBLAS')
    openblas_build_flags = [
        "NUM_THREADS=128",
        "USE_OPENMP=1",
        "NO_SHARED=0",
        "DYNAMIC_ARCH=1",
        "TARGET=ARMV8",
        "CFLAGS=-O3",
    ]
    openblas_checkout_dir = "OpenBLAS"

    check_call(
        [
            "git",
            "clone",
            "https://github.com/OpenMathLib/OpenBLAS.git",
            "-b",
            "v0.3.25",
            "--depth",
            "1",
            "--shallow-submodules",
        ]
    )

    check_call(["make", "-j8"]
                + openblas_build_flags,
                cwd=openblas_checkout_dir)
    check_call(["make", "-j8"]
                + openblas_build_flags
                + ["install"],
                cwd=openblas_checkout_dir)


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
            "v24.04",
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


def update_wheel(wheel_path) -> None:
    """
    Update the cuda wheel libraries
    """
    folder = os.path.dirname(wheel_path)
    wheelname = os.path.basename(wheel_path)
    os.mkdir(f"{folder}/tmp")
    os.system(f"unzip {wheel_path} -d {folder}/tmp")
    libs_to_copy = [
        "/usr/local/cuda/extras/CUPTI/lib64/libcupti.so.12",
        "/usr/local/cuda/lib64/libcudnn.so.8",
        "/usr/local/cuda/lib64/libcublas.so.12",
        "/usr/local/cuda/lib64/libcublasLt.so.12",
        "/usr/local/cuda/lib64/libcudart.so.12",
        "/usr/local/cuda/lib64/libcufft.so.11",
        "/usr/local/cuda/lib64/libcusparse.so.12",
        "/usr/local/cuda/lib64/libcusparseLt.so.0",
        "/usr/local/cuda/lib64/libcusolver.so.11",
        "/usr/local/cuda/lib64/libcurand.so.10",
        "/usr/local/cuda/lib64/libnvToolsExt.so.1",
        "/usr/local/cuda/lib64/libnvJitLink.so.12",
        "/usr/local/cuda/lib64/libnvrtc.so.12",
        "/usr/local/cuda/lib64/libnvrtc-builtins.so.12.4",
        "/usr/local/cuda/lib64/libcudnn_adv_infer.so.8",
        "/usr/local/cuda/lib64/libcudnn_adv_train.so.8",
        "/usr/local/cuda/lib64/libcudnn_cnn_infer.so.8",
        "/usr/local/cuda/lib64/libcudnn_cnn_train.so.8",
        "/usr/local/cuda/lib64/libcudnn_ops_infer.so.8",
        "/usr/local/cuda/lib64/libcudnn_ops_train.so.8",
        "/opt/conda/envs/aarch64_env/lib/libopenblas.so.0",
        "/opt/conda/envs/aarch64_env/lib/libgfortran.so.5",
        "/opt/conda/envs/aarch64_env/lib/libgomp.so.1",
        "/acl/build/libarm_compute.so",
        "/acl/build/libarm_compute_graph.so",
        "/acl/build/libarm_compute_core.so",
    ]
    # Copy libraries to unzipped_folder/a/lib
    for lib_path in libs_to_copy:
        lib_name = os.path.basename(lib_path)
        shutil.copy2(lib_path, f"{folder}/tmp/torch/lib/{lib_name}")
    os.system(
        f"cd {folder}/tmp/torch/lib/; patchelf --set-rpath '$ORIGIN' {folder}/tmp/torch/lib/libtorch_cuda.so"
    )
    os.mkdir(f"{folder}/cuda_wheel")
    os.system(f"cd {folder}/tmp/; zip -r {folder}/cuda_wheel/{wheelname} *")
    shutil.move(
        f"{folder}/cuda_wheel/{wheelname}",
        f"/dist/{wheelname}",
        copy_function=shutil.copy2,
    )
    os.system(f"rm -rf {folder}/tmp {folder}/dist/cuda_wheel/")


def complete_wheel(folder: str) -> str:
    """
    Complete wheel build and put in artifact location
    """
    wheel_name = list_dir(f"/{folder}/dist")[0]

    if "pytorch" in folder and not enable_cuda:
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

    print(f"Copying {repaired_wheel_name} to artifacts")
    shutil.copy2(
        f"/{folder}/dist/{repaired_wheel_name}", f"/artifacts/{repaired_wheel_name}"
    )

    return repaired_wheel_name


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

    build_OpenBLAS()
    if enable_mkldnn:
        build_ArmComputeLibrary()
        print("build pytorch with mkldnn+acl backend")
        build_vars += (
            "USE_MKLDNN=ON USE_MKLDNN_ACL=ON "
            "ACL_ROOT_DIR=/acl "
            "LD_LIBRARY_PATH=/pytorch/build/lib:/acl/build:$LD_LIBRARY_PATH "
            "ACL_INCLUDE_DIR=/acl/build "
            "ACL_LIBRARY=/acl/build "
            "BLAS=OpenBLAS "
            "OpenBLAS_HOME=/OpenBLAS "
        )
    else:
        print("build pytorch without mkldnn backend")

    os.system(f"cd /pytorch; {build_vars} python3 setup.py bdist_wheel")
    if enable_cuda:
        print("Updating Cuda Dependency")
        filename = os.listdir("/pytorch/dist/")
        wheel_path = f"/pytorch/dist/{filename[0]}"
        update_wheel(wheel_path)
    pytorch_wheel_name = complete_wheel("/pytorch/")
    print(f"Build Complete. Created {pytorch_wheel_name}..")
