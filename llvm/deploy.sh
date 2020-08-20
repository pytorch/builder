#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/env_vars.sh"

FORCE_PUSH=${FORCE_PUSH:-no}
IMAGE="pytorch/llvm:${LLVM_VERSION}"

if DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect "${IMAGE}" >/dev/null 2>/dev/null; then
  if [[ ${FORCE_PUSH} = "no" ]]; then
    echo "ERROR: ${IMAGE} already exists, run script with FORCE_PUSH=yes to forcefully push over the tag"
    exit 1
  else
    echo "WARNING: Overwriting existing ${IMAGE}"
  fi
fi
(
  set -x
  docker push "pytorch/llvm:${LLVM_VERSION}"
)
