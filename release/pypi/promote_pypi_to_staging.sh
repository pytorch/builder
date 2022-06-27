#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/../release_versions.sh"

DRY_RUN=${DRY_RUN:-enabled}

upload_pypi_to_staging() {
    local package_name
    package_name=$1
    local promote_version
    promote_version=$2
    echo "=-=-=-= Promoting ${package_name}'s v${promote_version} to pypi staging' =-=-=-="
    (
        set -x
        PACKAGE_VERSION="${promote_version}" PACKAGE_NAME="${package_name}" DRY_RUN="${DRY_RUN}" bash ${DIR}/upload_pypi_to_staging.sh
    )
    echo
}

# Uncomment these to promote to pypi
LINUX_VERSION_SUFFIX="%2Bcu102"
WIN_VERSION_SUFFIX="%2Bcpu"
PLATFORM="linux_x86_64"          VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" upload_pypi_to_staging torch "${PYTORCH_VERSION}"
PLATFORM="manylinux2014_aarch64" VERSION_SUFFIX=""                        upload_pypi_to_staging torch "${PYTORCH_VERSION}"
PLATFORM="win_amd64"             VERSION_SUFFIX="${WIN_VERSION_SUFFIX}"   upload_pypi_to_staging torch "${PYTORCH_VERSION}"
PLATFORM="macosx_10_9"           VERSION_SUFFIX=""                        upload_pypi_to_staging torch "${PYTORCH_VERSION}" # intel mac
PLATFORM="macosx_11_0"           VERSION_SUFFIX=""                        upload_pypi_to_staging torch "${PYTORCH_VERSION}" # m1 mac

PLATFORM="linux_x86_64"          VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"
PLATFORM="manylinux2014_aarch64" VERSION_SUFFIX=""                        upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"
PLATFORM="win_amd64"             VERSION_SUFFIX="${WIN_VERSION_SUFFIX}"   upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"
PLATFORM="macosx_10_9"           VERSION_SUFFIX=""                        upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"
PLATFORM="macosx_11_0"           VERSION_SUFFIX=""                        upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"

PLATFORM="linux_x86_64"          VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"
PLATFORM="manylinux2014_aarch64" VERSION_SUFFIX=""                        upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"
PLATFORM="win_amd64"             VERSION_SUFFIX="${WIN_VERSION_SUFFIX}"   upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"
PLATFORM="macosx_10_15"          VERSION_SUFFIX=""                        upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"
PLATFORM="macosx_11_0"           VERSION_SUFFIX=""                        upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"

upload_pypi_to_staging torchtext "${TORCHTEXT_VERSION}"
