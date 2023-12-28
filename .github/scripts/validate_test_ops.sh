#!/bin/bash

set -eux -o pipefail

retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

BRANCH=""
if [[ ${MATRIX_CHANNEL} == "test" ]]; then
    SHORT_VERSION=${MATRIX_STABLE_VERSION%.*}
    BRANCH="--branch release/${SHORT_VERSION}"
fi


# Clone the Pytorch branch
retry git clone ${BRANCH} --depth 1 https://github.com/pytorch/pytorch.git
retry git submodule update --init --recursive
pushd pytorch

pip install expecttest pyyaml jinja2 packaging

# Run test_ops validation
export CUDA_LAUNCH_BLOCKING=1
python3 test/test_ops.py
