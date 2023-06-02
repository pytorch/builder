#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

GPU_ARCH_VERSION=${GPU_ARCH_VERSION:-}

TARGET=rocm_prebuild
GPU_IMAGE=rocm/dev-centos-7:${GPU_ARCH_VERSION}-complete
DOCKER_IMAGE=rocm/dev-centos-7:${GPU_ARCH_VERSION}-magma-miopen-staging
PYTORCH_ROCM_ARCH="gfx900;gfx906;gfx908;gfx90a;gfx1030;gfx1100"
DOCKER_GPU_BUILD_ARG="--build-arg ROCM_VERSION=${GPU_ARCH_VERSION} --build-arg PYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH} --build-arg DEVTOOLSET_VERSION=9"

(
    set -x
    DOCKER_BUILDKIT=1 docker build \
        -t "${DOCKER_IMAGE}" \
        ${DOCKER_GPU_BUILD_ARG} \
        --build-arg "GPU_IMAGE=${GPU_IMAGE}" \
        --target "${TARGET}" \
        -f "${TOPDIR}/manywheel/Dockerfile" \
        "${TOPDIR}"
)

(
    set -x
    docker push "${DOCKER_IMAGE}"
)
