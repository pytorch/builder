#!/usr/bin/env bash

set -eou pipefail

# Make sure to update these versions when doing a release first
PYTORCH_VERSION=${PYTORCH_VERSION:-1.6.0}
TORCHVISION_VERSION=${TORCHVISION_VERSION:-0.7.0}
TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION:-0.6.0}
TORCHTEXT_VERSION=${TORCHTEXT_VERSION:-0.7.0}
TORCHSERVE_VERSION=${TORCHSERVE_VERSION:-0.2.1}
TORCHCSPRNG_VERSION=${TORCHCSPRNG_VERSION:-0.1.2}

PYTORCH_DIR=${PYTORCH_DIR:-~/pytorch}

DRY_RUN=${DRY_RUN:-enabled}

promote_s3() {
    local package_name
    package_name=$1
    local package_type
    package_type=$2
    local promote_version
    promote_version=$3

    echo "=-=-=-= Promoting ${package_name}'s v${promote_version} ${package_type} packages' =-=-=-="
    (
        set -x
        TEST_PYTORCH_PROMOTE_VERSION="${promote_version}" \
            PACKAGE_NAME="${package_name}" \
            PACKAGE_TYPE="${package_type}" \
            TEST_WITHOUT_GIT_TAG=1 \
            DRY_RUN="${DRY_RUN}" ${PYTORCH_DIR}/scripts/release/promote/s3_to_s3.sh
    )
    echo
}

promote_conda() {
    local package_name
    package_name=$1
    local package_type
    package_type=$2
    local promote_version
    promote_version=$3
    echo "=-=-=-= Promoting ${package_name}'s v${promote_version} ${package_type} packages' =-=-=-="
    (
        set -x
        TEST_PYTORCH_PROMOTE_VERSION="${promote_version}" \
            PACKAGE_NAME="${package_name}" \
            PACKAGE_TYPE="${package_type}" \
            TEST_WITHOUT_GIT_TAG=1 \
            DRY_RUN="${DRY_RUN}" ${PYTORCH_DIR}/scripts/release/promote/conda_to_conda.sh
    )
    echo
}

promote_pypi() {
    local package_name
    package_name=$1
    local promote_version
    promote_version=$2
    echo "=-=-=-= Promoting ${package_name}'s v${promote_version} to pypi' =-=-=-="
    (
        set -x
        TEST_PYTORCH_PROMOTE_VERSION="${promote_version}" \
            PACKAGE_NAME="${package_name}" \
            TEST_WITHOUT_GIT_TAG=1 \
            DRY_RUN="${DRY_RUN}" ${PYTORCH_DIR}/scripts/release/promote/wheel_to_pypi.sh
    )
    echo
}

promote_s3 torch whl "${PYTORCH_VERSION}"
promote_s3 torchvision whl "${TORCHVISION_VERSION}"
promote_s3 torchaudio whl "${TORCHAUDIO_VERSION}"
promote_s3 torchtext whl "${TORCHTEXT_VERSION}"
promote_s3 torchserve whl "${TORCHSERVE_VERSION}"
promote_s3 torch_model_archiver whl "${TORCHSERVE_VERSION}"
promote_s3 torchcsprng whl "${TORCHCSPRNG_VERSION}"

promote_s3 "libtorch-*" libtorch "${PYTORCH_VERSION}"

promote_conda pytorch conda "${PYTORCH_VERSION}"
promote_conda torchvision conda "${TORCHVISION_VERSION}"
promote_conda torchaudio conda "${TORCHAUDIO_VERSION}"
promote_conda torchtext conda "${TORCHTEXT_VERSION}"
promote_conda torchserve conda "${TORCHSERVE_VERSION}"
promote_conda torch-model-archiver conda "${TORCHSERVE_VERSION}"
promote_conda torchcsprng conda "${TORCHCSPRNG_VERSION}"

# Uncomment these to promote to pypi
# promote_pypi torch "${PYTORCH_VERSION}"
# promote_pypi torchvision "${TORCHVISION_VERSION}"
# promote_pypi torchaudio "${TORCHAUDIO_VERSION}"
# promote_pypi torchtext "${TORCHTEXT_VERSION}"
# promote_pypi torchcsprng "${TORCHCSPRNG_VERSION}"
