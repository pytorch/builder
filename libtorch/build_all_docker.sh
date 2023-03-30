#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

for cuda_version in 12.1 11.8 11.7; do
    GPU_ARCH_TYPE=cuda GPU_ARCH_VERSION="${cuda_version}" "${TOPDIR}/libtorch/build_docker.sh"
done

for rocm_version in 5.3 5.4.2; do
    GPU_ARCH_TYPE=rocm GPU_ARCH_VERSION="${rocm_version}" "${TOPDIR}/libtorch/build_docker.sh"
done
