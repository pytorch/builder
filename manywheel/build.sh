#!/usr/bin/env bash

set -ex

export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export NCCL_ROOT_DIR=/usr/local/cuda
export TH_BINARY_BUILD=1
export USE_STATIC_CUDNN=1
export USE_STATIC_NCCL=1
export ATEN_STATIC_CUDA=1
export USE_CUDA_STATIC_LINK=1
export INSTALL_TEST=0 # dont install test binaries into site-packages

# Keep an array of cmake variables to add to
if [[ -z "$CMAKE_ARGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build()
    CMAKE_ARGS=()
fi
if [[ -z "$EXTRA_CAFFE2_CMAKE_FLAGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build_caffe2()
    EXTRA_CAFFE2_CMAKE_FLAGS=()
fi

# Determine CUDA version and architectures to build for
CUDA_VERSION=$(nvcc --version|tail -n1|cut -f5 -d" "|cut -f1 -d",")
echo "CUDA $CUDA_VERSION Detected"

export TORCH_CUDA_ARCH_LIST="3.5;5.0+PTX"
if [[ $CUDA_VERSION == "9.0" ]]; then
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;7.0"
elif [[ $CUDA_VERSION == "9.2" ]]; then
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1;7.0"
    # ATen tests can't build with CUDA 9.2 and the old compiler used here
    EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
elif [[ $CUDA_VERSION == "10.0" ]]; then
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1;7.0;7.5"
    # ATen tests can't build with CUDA 10.0 maybe???? (todo) and the old compiler used here
    EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
elif [[ $CUDA_VERSION == "10.1" ]]; then
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1;7.0;7.5"
    # ATen tests can't build with CUDA 10.1 maybe???? (todo) and the old compiler used here
    EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
else
    echo "unknown cuda version $CUDA_VERSION"
    exit 1
fi
echo $TORCH_CUDA_ARCH_LIST

cuda_version_nodot=$(echo $CUDA_VERSION | tr -d '.')

# Package directories
WHEELHOUSE_DIR="wheelhouse$cuda_version_nodot"
LIBTORCH_HOUSE_DIR="libtorch_house$cuda_version_nodot"
if [[ -z "$PYTORCH_FINAL_PACKAGE_DIR" ]]; then
    if [[ -z "$BUILD_PYTHONLESS" ]]; then
        PYTORCH_FINAL_PACKAGE_DIR="/remote/wheelhouse$cuda_version_nodot"
    else
        PYTORCH_FINAL_PACKAGE_DIR="/remote/libtorch_house$cuda_version_nodot"
    fi
fi
mkdir -p "$PYTORCH_FINAL_PACKAGE_DIR" || true

if [[ $CUDA_VERSION == "9.0" ]]; then
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.9.0"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libnvrtc.so.9.0"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libcudart.so.9.0"
    "libnvToolsExt.so.1"
    "libnvrtc.so.9.0"
    "libnvrtc-builtins.so"
    "libgomp.so.1"
)
elif [[ $CUDA_VERSION == "9.2" ]]; then
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.9.2"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libnvrtc.so.9.2"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libcudart.so.9.2"
    "libnvToolsExt.so.1"
    "libnvrtc.so.9.2"
    "libnvrtc-builtins.so"
    "libgomp.so.1"
)
elif [[ $CUDA_VERSION == "10.0" ]]; then
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.10.0"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libnvrtc.so.10.0"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libcudart.so.10.0"
    "libnvToolsExt.so.1"
    "libnvrtc.so.10.0"
    "libnvrtc-builtins.so"
    "libgomp.so.1"
)
elif [[ $CUDA_VERSION == "10.1" ]]; then
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.10.1"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libnvrtc.so.10.1"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libcudart.so.10.1"
    "libnvToolsExt.so.1"
    "libnvrtc.so.10.1"
    "libnvrtc-builtins.so"
    "libgomp.so.1"
)
else
    echo "Unknown cuda version $CUDA_VERSION"
    exit 1
fi

# builder/test.sh requires DESIRED_CUDA to know what tests to exclude
export DESIRED_CUDA="$cuda_version_nodot"


SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
source $SCRIPTPATH/build_common.sh
