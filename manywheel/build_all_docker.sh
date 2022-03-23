#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

GPU_ARCH_TYPE=cpu "${TOPDIR}/manywheel/build_docker.sh"
MANYLINUX_VERSION=2014 GPU_ARCH_TYPE=cpu "${TOPDIR}/manywheel/build_docker.sh"

for cuda_version in 11.5 11.3 10.2; do
    GPU_ARCH_TYPE=cuda GPU_ARCH_VERSION="${cuda_version}" "${TOPDIR}/manywheel/build_docker.sh"
    MANYLINUX_VERSION=2014 GPU_ARCH_TYPE=cuda GPU_ARCH_VERSION="${cuda_version}" "${TOPDIR}/manywheel/build_docker.sh"
done

for rocm_version in 5.0 5.1; do
    GPU_ARCH_TYPE=rocm GPU_ARCH_VERSION="${rocm_version}" "${TOPDIR}/manywheel/build_docker.sh"
    MANYLINUX_VERSION=2014 GPU_ARCH_TYPE=rocm GPU_ARCH_VERSION="${rocm_version}" "${TOPDIR}/manywheel/build_docker.sh"
done
