#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/release_versions.sh"

# Make sure to update these versions when doing a release first
PYTORCH_VERSION=${PYTORCH_VERSION:-1.13.1}
TORCHVISION_VERSION=${TORCHVISION_VERSION:-0.14.1}
TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION:-0.13.1}
TORCHTEXT_VERSION=${TORCHTEXT_VERSION:-0.14.1}

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
            DRY_RUN="${DRY_RUN}" ${DIR}/promote/s3_to_s3.sh
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
        ANACONDA="echo + anaconda"
        if [[ "${DRY_RUN:-enabled}" = "disabled" ]]; then
            ANACONDA="anaconda"
            set -x
        else
            echo "DRY_RUN enabled not actually doing work"
        fi
        ${ANACONDA} copy --to-owner ${PYTORCH_CONDA_TO:-pytorch} ${PYTORCH_CONDA_FROM:-pytorch-test}/${package_name}/${promote_version}
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
            DRY_RUN="${DRY_RUN}" ${DIR}/promote/wheel_to_pypi.sh
    )
    echo
}

# promote_s3 torch whl "${PYTORCH_VERSION}"
# promote_s3 torchvision whl "${TORCHVISION_VERSION}"
# promote_s3 torchaudio whl "${TORCHAUDIO_VERSION}"
# promote_s3 torchtext whl "${TORCHTEXT_VERSION}"
# promote_s3 "libtorch-*" libtorch "${PYTORCH_VERSION}"

# promote_conda pytorch conda "${PYTORCH_VERSION}"
# promote_conda torchvision conda "${TORCHVISION_VERSION}"
# promote_conda torchaudio conda "${TORCHAUDIO_VERSION}"
# promote_conda torchtext conda "${TORCHTEXT_VERSION}"

# Uncomment these to promote to pypi
LINUX_VERSION_SUFFIX="%2Bcu102"
WIN_VERSION_SUFFIX="%2Bcpu"
# PLATFORM="linux_x86_64" VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" promote_pypi torch "${PYTORCH_VERSION}"
# PLATFORM="manylinux2014_aarch64" VERSION_SUFFIX="" promote_pypi torch "${PYTORCH_VERSION}"
# PLATFORM="win_amd64"    VERSION_SUFFIX="${WIN_VERSION_SUFFIX}"   promote_pypi torch "${PYTORCH_VERSION}"
# PLATFORM="macosx_10_9"  VERSION_SUFFIX=""                        promote_pypi torch "${PYTORCH_VERSION}" # intel mac
# PLATFORM="macosx_11_0"  VERSION_SUFFIX=""                        promote_pypi torch "${PYTORCH_VERSION}" # m1 mac

# PLATFORM="linux_x86_64" VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" promote_pypi torchvision "${TORCHVISION_VERSION}"
# PLATFORM="manylinux2014_aarch64" VERSION_SUFFIX="" promote_pypi torchvision "${TORCHVISION_VERSION}"
# PLATFORM="win_amd64"    VERSION_SUFFIX="${WIN_VERSION_SUFFIX}"   promote_pypi torchvision "${TORCHVISION_VERSION}"
# PLATFORM="macosx_10_9"  VERSION_SUFFIX=""                        promote_pypi torchvision "${TORCHVISION_VERSION}"
# PLATFORM="macosx_11_0"  VERSION_SUFFIX=""                        promote_pypi torchvision "${TORCHVISION_VERSION}"

# PLATFORM="linux_x86_64" VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" promote_pypi torchaudio "${TORCHAUDIO_VERSION}"
# PLATFORM="manylinux2014_aarch64" VERSION_SUFFIX="" promote_pypi torchaudio "${TORCHAUDIO_VERSION}"
# PLATFORM="win_amd64"    VERSION_SUFFIX="${WIN_VERSION_SUFFIX}"   promote_pypi torchaudio "${TORCHAUDIO_VERSION}"
# PLATFORM="macosx_10_15"  VERSION_SUFFIX=""                        promote_pypi torchaudio "${TORCHAUDIO_VERSION}"
# PLATFORM="macosx_11_0"  VERSION_SUFFIX=""                        promote_pypi torchaudio "${TORCHAUDIO_VERSION}"
