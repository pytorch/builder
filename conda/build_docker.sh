#!/usr/bin/env bash

set -eou pipefail

export DOCKER_BUILDKIT=1
TOPDIR=$(git rev-parse --show-toplevel)

CUDA_VERSION=${CUDA_VERSION:-10.2}

case ${CUDA_VERSION} in
  cpu)
    BASE_TARGET=base
    DOCKER_TAG=cpu
    ;;
  all)
    BASE_TARGET=all_cuda
    DOCKER_TAG=latest
    ;;
  *)
    BASE_TARGET=cuda${CUDA_VERSION}
    DOCKER_TAG=cuda${CUDA_VERSION}
    ;;
esac

(
  set -x
  docker build \
    --target final \
    --build-arg "BASE_TARGET=${BASE_TARGET}" \
    --build-arg "CUDA_VERSION=${CUDA_VERSION}" \
    -t "pytorch/conda-builder:${DOCKER_TAG}" \
    -f "${TOPDIR}/conda/Dockerfile" \
    ${TOPDIR}
)

if [[ "${DOCKER_TAG}" =~ ^cuda* ]]; then
  # Meant for legacy scripts since they only do the version without the "."
  # TODO: Eventually remove this
  (
    set -x
    docker tag "pytorch/conda-builder:${DOCKER_TAG}" "pytorch/conda-builder:cuda${CUDA_VERSION/./}"
  )
fi

if [[ -n "${WITH_PUSH:-}" ]]; then
  (
    set -x
    docker push "pytorch/conda-builder:${DOCKER_TAG}"
    if [[ "${DOCKER_TAG}" =~ ^cuda* ]]; then
      docker push "pytorch/conda-builder:cuda${CUDA_VERSION/./}"
    fi
  )
fi
