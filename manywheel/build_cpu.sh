#!/usr/bin/env bash

set -ex

GPU_ARCH_TYPE=${GPU_ARCH_TYPE:-cpu}

export TH_BINARY_BUILD=1
export USE_CUDA=0

# Keep an array of cmake variables to add to
if [[ -z "$CMAKE_ARGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build()
    CMAKE_ARGS=()
fi
if [[ -z "$EXTRA_CAFFE2_CMAKE_FLAGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build_caffe2()
    EXTRA_CAFFE2_CMAKE_FLAGS=()
fi

DIR_SUFFIX=cpu
if [[ "$GPU_ARCH_TYPE" == "xpu" ]]; then
    DIR_SUFFIX=xpu
    source /opt/intel/oneapi/pytorch-gpu-dev-0.5/oneapi-vars.sh
fi

WHEELHOUSE_DIR="wheelhouse$DIR_SUFFIX"
LIBTORCH_HOUSE_DIR="libtorch_house$DIR_SUFFIX"
if [[ -z "$PYTORCH_FINAL_PACKAGE_DIR" ]]; then
    if [[ -z "$BUILD_PYTHONLESS" ]]; then
        PYTORCH_FINAL_PACKAGE_DIR="/remote/wheelhouse$DIR_SUFFIX"
    else
        PYTORCH_FINAL_PACKAGE_DIR="/remote/libtorch_house$DIR_SUFFIX"
    fi
fi
mkdir -p "$PYTORCH_FINAL_PACKAGE_DIR" || true

OS_NAME=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
if [[ "$OS_NAME" == *"CentOS Linux"* ]]; then
    LIBGOMP_PATH="/usr/lib64/libgomp.so.1"
elif [[ "$OS_NAME" == *"Red Hat Enterprise Linux"* ]]; then
    LIBGOMP_PATH="/usr/lib64/libgomp.so.1"
elif [[ "$OS_NAME" == *"AlmaLinux"* ]]; then
    LIBGOMP_PATH="/usr/lib64/libgomp.so.1"
elif [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    if [[ "$(uname -m)" == "s390x" ]]; then
        LIBGOMP_PATH="/usr/lib/s390x-linux-gnu/libgomp.so.1"
    else
        LIBGOMP_PATH="/usr/lib/x86_64-linux-gnu/libgomp.so.1"
    fi
fi

DEPS_LIST=(
    "$LIBGOMP_PATH"
)

DEPS_SONAME=(
    "libgomp.so.1"
)

rm -rf /usr/local/cuda*

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
if [[ -z "$BUILD_PYTHONLESS" ]]; then
    BUILD_SCRIPT=build_common.sh
else
    BUILD_SCRIPT=build_libtorch.sh
fi
source ${SOURCE_DIR}/${BUILD_SCRIPT}
