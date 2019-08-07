#!/usr/bin/env bash

set -ex

export TH_BINARY_BUILD=1
export USE_CUDA=0

# yf225 TODO debug
echo "manywheel/build.sh: CXX_ABI_VARIANT: ", $CXX_ABI_VARIANT

# Keep an array of cmake variables to add to
if [[ -z "$CMAKE_ARGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build()
    CMAKE_ARGS=()
fi
if [[ -z "$EXTRA_CAFFE2_CMAKE_FLAGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build_caffe2()
    EXTRA_CAFFE2_CMAKE_FLAGS=()
fi

if [[ "$CXX_ABI_VARIANT" == "cxx11-abi" ]]; then
    CMAKE_ARGS+=("-D_GLIBCXX_USE_CXX11_ABI=$GLIBCXX_USE_CXX11_ABI")
fi

WHEELHOUSE_DIR="wheelhousecpu"
LIBTORCH_HOUSE_DIR="libtorch_housecpu"
if [[ -z "$PYTORCH_FINAL_PACKAGE_DIR" ]]; then
    if [[ -z "$BUILD_PYTHONLESS" ]]; then
        PYTORCH_FINAL_PACKAGE_DIR="/remote/wheelhousecpu"
    else
        PYTORCH_FINAL_PACKAGE_DIR="/remote/libtorch_housecpu"
    fi
fi
mkdir -p "$PYTORCH_FINAL_PACKAGE_DIR" || true


DEPS_LIST=(
    "/usr/lib/gcc/x86_64-linux-gnu/5/libgomp.so"
)

DEPS_SONAME=(
    "libgomp.so.1"
)

rm -rf /usr/local/cuda*

# builder/test.sh requires DESIRED_CUDA to know what tests to exclude
export DESIRED_CUDA='cpu'

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
source $SCRIPTPATH/build_common.sh
