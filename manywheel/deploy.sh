#!/usr/bin/env bash

set -eou pipefail

for rocm_version in 3.7.0; do
    (
        set -x
        # trailing patch version is omitted in some contexts
        dots="${rocm_version//[^.]}"
        if [ ${#dots} = 2 ]; then
            rocm_version_clean=${rocm_version%.0}
        else
            rocm_version_clean=${rocm_version}
        fi
        DOCKER_BUILDKIT=1 docker build \
            -t "pytorch/manylinux-rocm${rocm_version//./}" \
            --build-arg "BASE_ROCM_VERSION=${rocm_version}" \
            --build-arg "GPU_IMAGE=rocm/dev-centos-7:${rocm_version_clean}" \
            --target rocm_final \
            --progress=plain \
            -f manywheel/Dockerfile \
            .
        #docker push "pytorch/manylinux-rocm${rocm_version//./}"
    )
done

#for cuda_version in 9.2 10.1 10.2 11.0; do
#    (
#        set -x
#        DOCKER_BUILDKIT=1 docker build \
#            -t "pytorch/manylinux-cuda${cuda_version//./}" \
#            --build-arg "BASE_CUDA_VERSION=${cuda_version}" \
#            --build-arg "GPU_IMAGE=nvidia/cuda:${cuda_version}-devel-centos7" \
#            --target cuda_final \
#            -f manywheel/Dockerfile \
#            .
#        docker push "pytorch/manylinux-cuda${cuda_version//./}"
#    )
#done
