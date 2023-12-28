#!/bin/bash

set -eux -o pipefail

retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

# Clone the Pytorch branch
retry git clone --depth 1 https://github.com/pytorch/pytorch.git
retry git submodule update --init --recursive
pushd pytorch

pip install expecttest pyyaml jinja2

# Run test_ops validation
export CUDA_LAUNCH_BLOCKING=1
python3 test/test_ops.py
