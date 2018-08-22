#!/usr/bin/env bash

set -ex

export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export NCCL_ROOT_DIR=/usr/local/cuda
export TH_BINARY_BUILD=1
export USE_STATIC_CUDNN=1
export USE_STATIC_NCCL=1
export ATEN_STATIC_CUDA=1
export USE_CUDA_STATIC_LINK=1

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
if [[ $CUDA_VERSION == "8.0" ]]; then
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1"
elif [[ $CUDA_VERSION == "9.0" ]]; then
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;7.0"
elif [[ $CUDA_VERSION == "9.2" ]]; then
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1;7.0"
    # ATen tests can't build with CUDA 9.2 and the old compiler used here
    EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
else
    echo "unknown cuda version $CUDA_VERSION"
    exit 1
fi
echo $TORCH_CUDA_ARCH_LIST
WHEELHOUSE_DIR="wheelhouse${CUDA_VERSION:0:1}${CUDA_VERSION:2:1}"

if [[ $CUDA_VERSION == "8.0" ]]; then
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.8.0.61"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libnvrtc.so.8.0.61"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libcudart.so.8.0"
    "libnvToolsExt.so.1"
    "libnvrtc.so.8.0"
    "libnvrtc-builtins.so"
    "libgomp.so.1"
)

elif [[ $CUDA_VERSION == "9.0" ]]; then
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
else
    echo "Unknown cuda version $CUDA_VERSION"
    exit 1
fi

ALLOW_DISTRIBUTED_TEST_ERRORS=1

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
source $SCRIPTPATH/build_common.sh
