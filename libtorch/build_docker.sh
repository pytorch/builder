#!/usr/bin/env bash

export DOCKER_BUILDKIT=1
TOPDIR=$(git rev-parse --show-toplevel)

CUDA_VERSION=${CUDA_VERSION:-10.2}

case ${CUDA_VERSION} in
  cpu)
    BASE_TARGET=base
    DOCKER_TAG=cpu
    ;;
  *)
    BASE_TARGET=cuda${CUDA_VERSION}
    DOCKER_TAG=cuda${CUDA_VERSION}
    ;;
esac

DOCKER=${DOCKER:-docker}

(
  set -x
  ${DOCKER} build \
    --target final \
    --build-arg "BASE_TARGET=${BASE_TARGET}" \
    --build-arg "CUDA_VERSION=${CUDA_VERSION}" \
    -t "pytorch/libtorch-cxx11-builder:${DOCKER_TAG}" \
    -f "${TOPDIR}/libtorch/Dockerfile" \
    ${TOPDIR}
)

DOCKER_IMAGE=pytorch/libtorch-cxx11-builder:${DOCKER_TAG}
GITHUB_REF=${GITHUB_REF:-$(git symbolic-ref -q HEAD || git describe --tags --exact-match)}
GIT_BRANCH_NAME=${GITHUB_REF##*/}
GIT_COMMIT_SHA=${GITHUB_SHA:-$(git rev-parse HEAD)}
DOCKER_IMAGE_BRANCH_TAG=${DOCKER_IMAGE}-${GIT_BRANCH_NAME}
DOCKER_IMAGE_SHA_TAG=${DOCKER_IMAGE}-${GIT_COMMIT_SHA}

if [[ -n ${GITHUB_REF} ]]; then
    ${DOCKER} tag ${DOCKER_IMAGE} ${DOCKER_IMAGE_BRANCH_TAG}
    ${DOCKER} tag ${DOCKER_IMAGE} ${DOCKER_IMAGE_SHA_TAG}
fi

if [[ "${WITH_PUSH:-}" == true ]]; then
  (
    set -x
    ${DOCKER} push "${DOCKER_IMAGE}"
    if [[ -n ${GITHUB_REF} ]]; then
        ${DOCKER} push "${DOCKER_IMAGE_BRANCH_TAG}"
        ${DOCKER} push "${DOCKER_IMAGE_SHA_TAG}"
    fi
  )
  # For legacy .circleci/config.yml generation scripts
  if [[ "${CUDA_VERSION}" != "cpu" ]]; then
    (
      set -x
      ${DOCKER} tag ${DOCKER_IMAGE} pytorch/libtorch-cxx11-builder:${DOCKER_TAG/./}
      ${DOCKER} push pytorch/libtorch-cxx11-builder:${DOCKER_TAG/./}
    )
  fi
fi
