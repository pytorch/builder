#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

for CUDA_VERSION in 11.8 11.7 11.6 cpu; do
  CUDA_VERSION="${CUDA_VERSION}" conda/build_docker.sh
done
