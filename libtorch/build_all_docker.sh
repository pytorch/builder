#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

for CUDA_VERSION in 11.3 11.1 10.2 cpu; do
  CUDA_VERSION="${CUDA_VERSION}" libtorch/build_docker.sh
done
