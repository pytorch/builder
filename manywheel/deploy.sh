#!/usr/bin/env bash

set -eou pipefail

DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"

for rocm_version in 4.0.1 4.1; do
    DOCKER_IMAGE="${DOCKER_REGISTRY}/pytorch/manylinux-rocm:${rocm_version}"
    (
        set -x
        DOCKER_BUILDKIT=1 docker build \
            -t "${DOCKER_IMAGE}" \
            --build-arg "ROCM_VERSION=${rocm_version}" \
            --build-arg "GPU_IMAGE=rocm/dev-centos-7:${rocm_version}" \
            --target rocm_final \
            -f manywheel/Dockerfile \
            .
        docker push "${DOCKER_IMAGE}"
    )
done

for cuda_version in 10.2 11.1; do
    DOCKER_IMAGE="${DOCKER_REGISTRY}/pytorch/manylinux-cuda${cuda_version//./}"
    (
        set -x
        DOCKER_BUILDKIT=1 docker build \
            -t "${DOCKER_IMAGE}" \
            --build-arg "BASE_CUDA_VERSION=${cuda_version}" \
            --build-arg "GPU_IMAGE=nvidia/cuda:${cuda_version}-devel-centos7" \
            --target cuda_final \
            -f manywheel/Dockerfile \
            .
        docker push ${DOCKER_IMAGE}
    )
done

(
    set -x
    DOCKER_BUILDKIT=1 docker build \
        -t "pytorch/manylinux-cpu" \
        --build-arg "GPU_IMAGE=centos:7" \
        --target cpu_final \
        -f manywheel/Dockerfile \
        .
        docker push "${DOCKER_REGISTRY}/pytorch/manylinux-cpu"
)
