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
LINUX_VERSION_SUFFIX="%2Bcu124"
CPU_VERSION_SUFFIX="%2Bcpu"
MACOS_X86_64="macosx_.*_x86_64"
MACOS_ARM64="macosx_.*_arm64"

PLATFORM="linux_x86_64"          VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" ARCH="cu124" upload_pypi_to_staging torch "${PYTORCH_VERSION}"
PLATFORM="manylinux2014_aarch64" VERSION_SUFFIX=""                                     upload_pypi_to_staging torch "${PYTORCH_VERSION}"
PLATFORM="win_amd64"             VERSION_SUFFIX="${CPU_VERSION_SUFFIX}"                upload_pypi_to_staging torch "${PYTORCH_VERSION}"
PLATFORM="${MACOS_ARM64}"        VERSION_SUFFIX=""                                     upload_pypi_to_staging torch "${PYTORCH_VERSION}"

PLATFORM="linux_x86_64"          VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" ARCH="cu124" upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"
PLATFORM="linux_aarch64"         VERSION_SUFFIX=""                                     upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"
PLATFORM="win_amd64"             VERSION_SUFFIX="${CPU_VERSION_SUFFIX}"                upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"
PLATFORM="${MACOS_ARM64}"        VERSION_SUFFIX=""                                     upload_pypi_to_staging torchvision "${TORCHVISION_VERSION}"

PLATFORM="linux_x86_64"          VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" ARCH="cu124" upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"
PLATFORM="linux_aarch64"         VERSION_SUFFIX=""                                     upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"
PLATFORM="win_amd64"             VERSION_SUFFIX="${CPU_VERSION_SUFFIX}"                upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"
PLATFORM="${MACOS_ARM64}"        VERSION_SUFFIX=""                                     upload_pypi_to_staging torchaudio "${TORCHAUDIO_VERSION}"

#PLATFORM="manylinux2014_x86_64" VERSION_SUFFIX="${LINUX_VERSION_SUFFIX}" upload_pypi_to_staging torchao "${TORCHAO_VERSION}"
#PLATFORM="" VERSION_SUFFIX="${CPU_VERSION_SUFFIX}" upload_pypi_to_staging torchtune "${TORCHTUNE_VERSION}"

#PLATFORM="linux_x86" VERSION_SUFFIX="${CPU_VERSION_SUFFIX}" upload_pypi_to_staging executorch "${EXECUTORCH_VERSION}"
#PLATFORM="${MACOS_ARM64}" VERSION_SUFFIX="" upload_pypi_to_staging executorch "${EXECUTORCH_VERSION}"

#PLATFORM="linux_x86" VERSION_SUFFIX="${CPU_VERSION_SUFFIX}" upload_pypi_to_staging torchtext "${TORCHTEXT_VERSION}"
#PLATFORM="win_amd64" VERSION_SUFFIX="${CPU_VERSION_SUFFIX}" upload_pypi_to_staging torchtext "${TORCHTEXT_VERSION}"
#PLATFORM="${MACOS_ARM64}" VERSION_SUFFIX="" upload_pypi_to_staging torchtext "${TORCHTEXT_VERSION}"

#PLATFORM="linux_x86_64" VERSION_SUFFIX="${CPU_VERSION_SUFFIX}" upload_pypi_to_staging torchdata "${TORCHDATA_VERSION}"
#PLATFORM="win_amd64" VERSION_SUFFIX="" upload_pypi_to_staging torchdata "${TORCHDATA_VERSION}"
#PLATFORM="${MACOS_ARM64}" VERSION_SUFFIX="" upload_pypi_to_staging torchdata "${TORCHDATA_VERSION}"
