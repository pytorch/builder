#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

for CUDA_VERSION in 11.2 11.1 11.0 10.2 10.1 cpu; do
  CUDA_VERSION="${CUDA_VERSION}" conda/build_docker.sh
done
