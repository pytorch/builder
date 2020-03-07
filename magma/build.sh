#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUILDER_IMAGE="pytorch/magma-builder"
DESIRED_CUDA=${DESIRED_CUDA:-10.2}

# Do this so we don't have to send a docker context
cat "${DIR}/Dockerfile" | docker build -t "${BUILDER_IMAGE}" -

docker run --rm -i \
    -v $(git rev-parse --show-toplevel):/builder \
    -w /builder \
    -e "DESIRED_CUDA=${DESIRED_CUDA}" \
    "${BUILDER_IMAGE}" \
    magma/build_magma.sh
