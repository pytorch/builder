#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

for cuda_version in 11.6 11.5 11.3 10.2; do
    GPU_ARCH_TYPE=cuda GPU_ARCH_VERSION="${cuda_version}" "${TOPDIR}/libtorch/build_docker.sh"
done

for rocm_version in 4.5.2 5.0; do
    GPU_ARCH_TYPE=rocm GPU_ARCH_VERSION="${rocm_version}" "${TOPDIR}/libtorch/build_docker.sh"
done
