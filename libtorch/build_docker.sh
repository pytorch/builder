#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

GPU_ARCH_TYPE=${GPU_ARCH_TYPE:-cpu}
GPU_ARCH_VERSION=${GPU_ARCH_VERSION:-}

WITH_PUSH=${WITH_PUSH:-}

DOCKER=${DOCKER:-docker}

case ${GPU_ARCH_TYPE} in
    cpu)
        BASE_TARGET=cpu
        DOCKER_TAG=cpu
        GPU_IMAGE=nvidia/cuda:10.2-devel-ubuntu18.04
        DOCKER_GPU_BUILD_ARG=""
        ;;
    cuda)
        BASE_TARGET=cuda${GPU_ARCH_VERSION}
        DOCKER_TAG=cuda${GPU_ARCH_VERSION}
        GPU_IMAGE=nvidia/cuda:10.2-devel-ubuntu18.04
        DOCKER_GPU_BUILD_ARG=""
        ;;
    rocm)
        BASE_TARGET=rocm${GPU_ARCH_VERSION}
        DOCKER_TAG=rocm${GPU_ARCH_VERSION}
        GPU_IMAGE=rocm/dev-ubuntu-20.04:${GPU_ARCH_VERSION}-magma
        PYTORCH_ROCM_ARCH="gfx900;gfx906;gfx908"
        ROCM_REGEX="([0-9]+)\.([0-9]+)[\.]?([0-9]*)"
        if [[ $GPU_ARCH_VERSION =~ $ROCM_REGEX ]]; then
            ROCM_VERSION_INT=$((${BASH_REMATCH[1]}*10000 + ${BASH_REMATCH[2]}*100 + ${BASH_REMATCH[3]:-0}))
        else
            echo "ERROR: rocm regex failed"
            exit 1
        fi
        if [[ $ROCM_VERSION_INT -ge 40300 ]]; then
            PYTORCH_ROCM_ARCH="${PYTORCH_ROCM_ARCH};gfx90a;gfx1030"
        fi
        DOCKER_GPU_BUILD_ARG="--build-arg PYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH}"
        ;;
    *)
        echo "ERROR: Unrecognized GPU_ARCH_TYPE: ${GPU_ARCH_TYPE}"
        exit 1
        ;;
esac

DOCKER_IMAGE=pytorch/libtorch-cxx11-builder:${DOCKER_TAG}

(
    set -x
    DOCKER_BUILDKIT=1 ${DOCKER} build \
        -t "${DOCKER_IMAGE}" \
        ${DOCKER_GPU_BUILD_ARG} \
        --build-arg "GPU_IMAGE=${GPU_IMAGE}" \
        --build-arg "BASE_TARGET=${BASE_TARGET}" \
        --target final \
        -f "${TOPDIR}/libtorch/Dockerfile" \
        "${TOPDIR}"
)

GITHUB_REF=${GITHUB_REF:-$(git symbolic-ref -q HEAD || git describe --tags --exact-match)}
GIT_BRANCH_NAME=${GITHUB_REF##*/}
GIT_COMMIT_SHA=${GITHUB_SHA:-$(git rev-parse HEAD)}
DOCKER_IMAGE_BRANCH_TAG=${DOCKER_IMAGE}-${GIT_BRANCH_NAME}
DOCKER_IMAGE_SHA_TAG=${DOCKER_IMAGE}-${GIT_COMMIT_SHA}

if [[ -n ${GITHUB_REF} ]]; then
    ${DOCKER} tag ${DOCKER_IMAGE} ${DOCKER_IMAGE_BRANCH_TAG}
    ${DOCKER} tag ${DOCKER_IMAGE} ${DOCKER_IMAGE_SHA_TAG}
fi

if [[ "${WITH_PUSH}" == true ]]; then
  (
    set -x
    ${DOCKER} push "${DOCKER_IMAGE}"
    if [[ -n ${GITHUB_REF} ]]; then
        ${DOCKER} push "${DOCKER_IMAGE_BRANCH_TAG}"
        ${DOCKER} push "${DOCKER_IMAGE_SHA_TAG}"
    fi
  )
  # For legacy .circleci/config.yml generation scripts
  if [[ "${GPU_ARCH_TYPE}" != "cpu" ]]; then
    (
      set -x
      ${DOCKER} tag ${DOCKER_IMAGE} pytorch/libtorch-cxx11-builder:${DOCKER_TAG/./}
      ${DOCKER} push pytorch/libtorch-cxx11-builder:${DOCKER_TAG/./}
    )
  fi
fi
