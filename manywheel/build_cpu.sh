#!/usr/bin/env bash

set -ex

export TH_BINARY_BUILD=1
export NO_CUDA=1

# Keep an array of cmake variables to add to
if [[ -z "$CMAKE_ARGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build()
    export CMAKE_ARGS=()
fi
if [[ -z "$EXTRA_CAFFE2_CMAKE_FLAGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build_caffe2()
    export EXTRA_CAFFE2_CMAKE_FLAGS=()
fi

export WHEELHOUSE_DIR="wheelhousecpu"

export DEPS_LIST=(
    "/usr/lib64/libgomp.so.1"
)

export DEPS_SONAME=(
    "libgomp.so.1"
)

rm -rf /usr/local/cuda*

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
bash $SCRIPTPATH/build_common.sh
