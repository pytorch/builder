#!/usr/bin/env bash

set -eou pipefail

BUILDER_IMAGE="pytorch/conda-cuda"
DESIRED_CUDA=${DESIRED_CUDA:-10.2}

docker run --rm -i \
    -v $(git rev-parse --show-toplevel):/builder \
    -w /builder \
    -e "DESIRED_CUDA=${DESIRED_CUDA}" \
    "${BUILDER_IMAGE}" \
    magma/build_magma.sh
