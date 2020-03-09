#!/usr/bin/env bash

set -eou pipefail

build_image() {
    BASE_CUDA_VERSION=$1
}

for cuda_version in 9.2 10.0 10.1 10.2; do
    (
        set -x
        docker build \
            -t "pytorch/manylinux-cuda${cuda_version//./}" \
            --build-arg "BASE_CUDA_VERSION=${cuda_version}" \
            -f manywheel/Dockerfile \
            .
        docker push "pytorch/manylinux-cuda${cuda_version//./}"
    )
done
