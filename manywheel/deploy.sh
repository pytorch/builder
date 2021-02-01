#!/usr/bin/env bash

set -eou pipefail

for rocm_version in 3.7 3.8 3.9 3.10 4.0 4.0.1; do
    (
        set -x
        DOCKER_BUILDKIT=1 docker build \
            -t "pytorch/manylinux-rocm:${rocm_version}" \
            --build-arg "ROCM_VERSION=${rocm_version}" \
            --build-arg "GPU_IMAGE=rocm/dev-centos-7:${rocm_version}" \
            --target rocm_final \
            -f manywheel/Dockerfile \
            .
        docker push "pytorch/manylinux-rocm:${rocm_version}"
    )
done

for cuda_version in 9.2 10.1 10.2 11.0 11.1 11.2; do
    (
        set -x
        DOCKER_BUILDKIT=1 docker build \
            -t "pytorch/manylinux-cuda${cuda_version//./}" \
            --build-arg "BASE_CUDA_VERSION=${cuda_version}" \
            --build-arg "GPU_IMAGE=nvidia/cuda:${cuda_version}-devel-centos7" \
            --target cuda_final \
            -f manywheel/Dockerfile \
            .
        docker push "pytorch/manylinux-cuda${cuda_version//./}"
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
        docker push "pytorch/manylinux-cpu"
)
