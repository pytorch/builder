#!/usr/bin/env bash

set -eou pipefail

# Create a folder to be packaged
PACKAGE_DIR=magma/${PACKAGE_NAME}
PACKAGE_FILES=magma/package_files
mkdir ${PACKAGE_DIR}
cp ${PACKAGE_FILES}/build.sh ${PACKAGE_DIR}/build.sh
cp ${PACKAGE_FILES}/meta.yaml ${PACKAGE_DIR}/meta.yaml
cp ${PACKAGE_FILES}/thread_queue.patch ${PACKAGE_DIR}/thread_queue.patch
cp ${PACKAGE_FILES}/cmakelists.patch ${PACKAGE_DIR}/cmakelists.patch
cp ${PACKAGE_FILES}/getrf_shfl.patch ${PACKAGE_DIR}/getrf_shfl.patch
cp ${PACKAGE_FILES}/getrf_nbparam.patch ${PACKAGE_DIR}/getrf_nbparam.patch

conda install -yq conda-build conda-verify
. ./conda/switch_cuda_version.sh "${DESIRED_CUDA}"
(
    set -x
    conda build --output-folder magma/output "${PACKAGE_DIR}"
)
