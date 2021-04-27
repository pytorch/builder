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

(
  set -x
  docker build \
    --target final \
    --build-arg "BASE_TARGET=${BASE_TARGET}" \
    --build-arg "CUDA_VERSION=${CUDA_VERSION}" \
    -t "pytorch/libtorch-cxx11-builder:${DOCKER_TAG}" \
    -f "${TOPDIR}/libtorch/ubuntu16.04/Dockerfile" \
    ${TOPDIR}
)


if [[ -n "${WITH_PUSH:-}" ]]; then
  (
    set -x
    docker push pytorch/libtorch-cxx11-builder:${DOCKER_TAG}
  )
  # For legacy .circleci/config.yml generation scripts
  if [[ "${CUDA_VERSION}" != "cpu" ]]; then
    (
      set -x
      docker tag \
        pytorch/libtorch-cxx11-builder:${DOCKER_TAG} \
        pytorch/libtorch-cxx11-builder:${DOCKER_TAG/./}
      docker push pytorch/libtorch-cxx11-builder:${DOCKER_TAG/./}
    )
  fi
fi
