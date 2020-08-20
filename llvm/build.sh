#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/env_vars.sh"

(
  set -x
  cat Dockerfile | DOCKER_BUILDKIT=1 docker build --build-arg "LLVM_VERSION=${LLVM_VERSION}" -t "pytorch/llvm:${LLVM_VERSION}" -
)
