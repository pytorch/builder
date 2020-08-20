#!/usr/bin/env bash

set -eou pipefail

MAGMA_VERSION="2.5.2"

function do_install() {
    cuda_version=$1
    cuda_version_nodot=${1/./}
    magma_archive="magma-cuda${cuda_version_nodot}-${MAGMA_VERSION}-1.tar.bz2"
    cuda_dir="/usr/local/cuda-${cuda_version}"
    (
        set -x
        wget -q https://anaconda.org/pytorch/magma-cuda${cuda_version_nodot}/${MAGMA_VERSION}/download/linux-64/${magma_archive}
        tar -xvf "${magma_archive}"
        mkdir -p "${cuda_dir}/magma"
        mv include "${cuda_dir}/magma/include"
        mv lib "${cuda_dir}/magma/lib"
        rm -rf info lib include "${magma_archive}"
    )
}

do_install $1
