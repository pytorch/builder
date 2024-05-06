#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

GPU_ARCH_TYPE=cpu "${TOPDIR}/manywheel/build_docker.sh"
MANYLINUX_VERSION=2014 GPU_ARCH_TYPE=cpu "${TOPDIR}/manywheel/build_docker.sh"

GPU_ARCH_TYPE=cpu-aarch64 "${TOPDIR}/manywheel/build_docker.sh"

GPU_ARCH_TYPE=cpu-s390x "${TOPDIR}/manywheel/build_docker.sh"

GPU_ARCH_TYPE=cpu-cxx11-abi "${TOPDIR}/manywheel/build_docker.sh"

for cuda_version in 12.1 11.8; do
    GPU_ARCH_TYPE=cuda GPU_ARCH_VERSION="${cuda_version}" "${TOPDIR}/manywheel/build_docker.sh"
    MANYLINUX_VERSION=2014 GPU_ARCH_TYPE=cuda GPU_ARCH_VERSION="${cuda_version}" "${TOPDIR}/manywheel/build_docker.sh"
done

for rocm_version in 6.0 6.1; do
    GPU_ARCH_TYPE=rocm GPU_ARCH_VERSION="${rocm_version}" "${TOPDIR}/manywheel/build_docker.sh"
    MANYLINUX_VERSION=2014 GPU_ARCH_TYPE=rocm GPU_ARCH_VERSION="${rocm_version}" "${TOPDIR}/manywheel/build_docker.sh"
done
