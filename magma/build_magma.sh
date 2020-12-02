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

# The cudaPointerAttributes patch for an API change on CUDA 11+
if [[ $DESIRED_CUDA == 11* ]]; then
    cp ${PACKAGE_FILES}/cudaPointerAttributes.patch ${PACKAGE_DIR}/cudaPointerAttributes.patch
fi

conda install -yq conda-build conda-verify
. ./conda/switch_cuda_version.sh "${DESIRED_CUDA}"
(
    set -x
    conda build --output-folder magma/output "${PACKAGE_DIR}"
)
