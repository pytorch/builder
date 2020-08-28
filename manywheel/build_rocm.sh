#!/usr/bin/env bash

set -ex

#export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
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

# Determine ROCm version and architectures to build for
if [[ -n "$DESIRED_ROCM" ]]; then
    # e.g., 3.5.1, 3.7
    ROCM_VERSION=${DESIRED_ROCM}
    echo "Using ROCM $ROCM_VERSION as determined by DESIRED_ROCM"
else
    echo "DESIRED_ROCM not set"
    exit 1
fi

rocm_version="_rocm_${ROCM_VERSION}"

# Package directories
WHEELHOUSE_DIR="wheelhouse$rocm_version"
LIBTORCH_HOUSE_DIR="libtorch_house$rocm_version"
if [[ -z "$PYTORCH_FINAL_PACKAGE_DIR" ]]; then
    if [[ -z "$BUILD_PYTHONLESS" ]]; then
        PYTORCH_FINAL_PACKAGE_DIR="/remote/wheelhouse$rocm_version"
    else
        PYTORCH_FINAL_PACKAGE_DIR="/remote/libtorch_house$rocm_version"
    fi
fi
mkdir -p "$PYTORCH_FINAL_PACKAGE_DIR" || true

OS_NAME=`awk -F= '/^NAME/{print $2}' /etc/os-release`
if [[ "$OS_NAME" == *"CentOS Linux"* ]]; then
    LIBGOMP_PATH="/usr/lib64/libgomp.so.1"
elif [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    LIBGOMP_PATH="/usr/lib/x86_64-linux-gnu/libgomp.so.1"
fi

if [[ $ROCM_VERSION == "3.7" ]]; then
DEPS_LIST=(
    "/opt/rocm/hip/lib/libamdhip64.so.3"
    "/opt/rocm/lib/libhsa-runtime64.so.1"
    "/opt/rocm/lib/libhsakmt.so.1"
    "$LIBGOMP_PATH"
)
DEPS_SONAME=(
    "libamdhip64.so.3"
    "libhsa-runtime64.so.1"
    "libhsakmt.so.1"
    "libgomp.so.1"
)
else
    echo "Unknown ROCm version $ROCM_VERSION"
    exit 1
fi

export ROCM_VERSION=$(ls /opt/rocm/lib/libamdhip64.so.*|sort|tac | head -1 | rev | cut -d"." -f -3 | rev) # 10.0.130
export ROCM_VERSION_SHORT=$(ls /opt/rocm/lib/libamdhip64.so.*|sort|tac | head -1 | rev | cut -d"." -f -3 | rev | cut -f1,2 -d".") # 10.0

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
if [[ -z "$BUILD_PYTHONLESS" ]]; then
    BUILD_SCRIPT=build_common.sh
else
    BUILD_SCRIPT=build_libtorch.sh
fi
source $SCRIPTPATH/${BUILD_SCRIPT}
