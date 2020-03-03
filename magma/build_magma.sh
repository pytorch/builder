#!/usr/bin/env bash

set -eou pipefail

conda install -yq conda-build conda-verify
. ./conda/switch_cuda_version.sh "${DESIRED_CUDA}"
(
    set -x
    conda build --output-folder magma/output "magma/magma-cuda${DESIRED_CUDA//./}"
)
