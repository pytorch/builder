#!/usr/bin/env bash

set -eou pipefail

TOPDIR=$(git rev-parse --show-toplevel)

DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"

GPU_ARCH_TYPE=${GPU_ARCH_TYPE:-cpu}
GPU_ARCH_VERSION=${GPU_ARCH_VERSION:-}
MANY_LINUX_VERSION=${MANY_LINUX_VERSION:-}

WITH_PUSH=${WITH_PUSH:-}

case ${GPU_ARCH_TYPE} in
    cpu)
        TARGET=cpu_final
        DOCKER_TAG=cpu
        LEGACY_DOCKER_IMAGE=${DOCKER_REGISTRY}/pytorch/manylinux-cpu
        GPU_IMAGE=centos:7
        DOCKER_GPU_BUILD_ARG=" --build-arg DEVTOOLSET_VERSION=9"
        ;;
    cpu-cxx11-abi)
        TARGET=final
        DOCKER_TAG=cpu-cxx11-abi
        LEGACY_DOCKER_IMAGE=${DOCKER_REGISTRY}/pytorch/manylinux-cpu-cxx11-abi
        GPU_IMAGE=""
        DOCKER_GPU_BUILD_ARG=" --build-arg DEVTOOLSET_VERSION=9"
        MANY_LINUX_VERSION="cxx11-abi"
        ;;
    cuda)
        TARGET=cuda_final
        DOCKER_TAG=cuda${GPU_ARCH_VERSION}
        LEGACY_DOCKER_IMAGE=${DOCKER_REGISTRY}/pytorch/manylinux-cuda${GPU_ARCH_VERSION//./}
        # Keep this up to date with the minimum version of CUDA we currently support
        GPU_IMAGE=nvidia/cuda:10.2-devel-centos7
        DEVTOOLSET_VERSION = 9
        if [[ ${GPU_ARCH_VERSION}  == 10.2]]; then
            DEVTOOLSET_VERSION = 7
        fi
        DOCKER_GPU_BUILD_ARG="--build-arg BASE_CUDA_VERSION=${GPU_ARCH_VERSION} --build-arg DEVTOOLSET_VERSION=${DEVTOOLSET_VERSION}"
        ;;
    rocm)
        TARGET=rocm_final
        DOCKER_TAG=rocm${GPU_ARCH_VERSION}
        LEGACY_DOCKER_IMAGE=${DOCKER_REGISTRY}/pytorch/manylinux-rocm:${GPU_ARCH_VERSION}
        GPU_IMAGE=rocm/dev-centos-7:${GPU_ARCH_VERSION}
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
        DOCKER_GPU_BUILD_ARG="--build-arg ROCM_VERSION=${GPU_ARCH_VERSION} --build-arg PYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH}"
        ;;
    *)
        echo "ERROR: Unrecognized GPU_ARCH_TYPE: ${GPU_ARCH_TYPE}"
        exit 1
        ;;
esac

IMAGES=''
DOCKER_NAME=manylinux${MANY_LINUX_VERSION}
DOCKER_IMAGE=${DOCKER_REGISTRY}/pytorch/${DOCKER_NAME}-builder:${DOCKER_TAG}
if [[ -n ${MANY_LINUX_VERSION} ]]; then
    DOCKERFILE_SUFFIX=_${MANY_LINUX_VERSION}
    LEGACY_DOCKER_IMAGE=''
else
    DOCKERFILE_SUFFIX=''
fi
(
    set -x
    DOCKER_BUILDKIT=1 docker build \
        -t "${DOCKER_IMAGE}" \
        ${DOCKER_GPU_BUILD_ARG} \
        --build-arg "GPU_IMAGE=${GPU_IMAGE}" \
        --target "${TARGET}" \
        -f "${TOPDIR}/manywheel/Dockerfile${DOCKERFILE_SUFFIX}" \
        "${TOPDIR}"
)

GITHUB_REF=${GITHUB_REF:-$(git symbolic-ref -q HEAD || git describe --tags --exact-match)}
GIT_BRANCH_NAME=${GITHUB_REF##*/}
GIT_COMMIT_SHA=${GITHUB_SHA:-$(git rev-parse HEAD)}
DOCKER_IMAGE_BRANCH_TAG=${DOCKER_IMAGE}-${GIT_BRANCH_NAME}
DOCKER_IMAGE_SHA_TAG=${DOCKER_IMAGE}-${GIT_COMMIT_SHA}

(
    set -x
    if [[ -n ${LEGACY_DOCKER_IMAGE} ]]; then
        docker tag ${DOCKER_IMAGE} ${LEGACY_DOCKER_IMAGE}
    fi
    if [[ -n ${GITHUB_REF} ]]; then
        docker tag ${DOCKER_IMAGE} ${DOCKER_IMAGE_BRANCH_TAG}
        docker tag ${DOCKER_IMAGE} ${DOCKER_IMAGE_SHA_TAG}
    fi
)

if [[ "${WITH_PUSH}" == true ]]; then
    (
        set -x
        docker push "${DOCKER_IMAGE}"
        if [[ -n ${LEGACY_DOCKER_IMAGE} ]]; then
            docker push "${LEGACY_DOCKER_IMAGE}"
        fi
        if [[ -n ${GITHUB_REF} ]]; then
            docker push "${DOCKER_IMAGE_BRANCH_TAG}"
            docker push "${DOCKER_IMAGE_SHA_TAG}"
        fi
    )
fi
