#!/bin/bash

set -eux -o pipefail

retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

BRANCH = "@main"
if [[ ${MATRIX_CHANNEL} == "test" ]]
    SHORT_VERSION=${MATRIX_STABLE_VERSION%.*}
    BRANCH="@release/${SHORT_VERSION}"
fi


# Clone the Pytorch branch
retry git clone --depth 1 https://github.com/pytorch/pytorch.git${BRANCH}
retry git submodule update --init --recursive
pushd pytorch

pip install expecttest pyyaml jinja2 packaging

# Run test_ops validation
export CUDA_LAUNCH_BLOCKING=1
python3 test/test_ops.py
