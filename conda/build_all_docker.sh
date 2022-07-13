#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

for CUDA_VERSION in 11.7 11.6 11.5 11.3 10.2 cpu cpu-cxx11-abi; do
  CUDA_VERSION="${CUDA_VERSION}" conda/build_docker.sh
done
