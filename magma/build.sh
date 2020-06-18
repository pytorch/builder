#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESIRED_CUDA=${DESIRED_CUDA:-11.0}

docker run --rm -i \
    -v $(git rev-parse --show-toplevel):/builder \
    -w /builder \
    -e "DESIRED_CUDA=${DESIRED_CUDA}" \
    "pytorch/conda-cuda:latest" \
    magma/build_magma.sh
