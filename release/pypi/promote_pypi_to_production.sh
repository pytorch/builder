#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/../release_versions.sh"

PYTORCH_DIR=${PYTORCH_DIR:-~/pytorch}

DRY_RUN=${DRY_RUN:-enabled}

TWINE_UPLOAD="true twine upload"
if [[ ${DRY_RUN:-enabled} = "disabled" ]]; then
    TWINE_UPLOAD="twine upload"
fi

promote_staging_binaries() {
    local package_name
    package_name=$1
    local promote_version
    promote_version=$2

    (
        TMP_DIR=$(mktemp -d)
        trap 'rm -rf ${TMP_DIR}' EXIT
        pushd "${TMP_DIR}"
        set -x
        aws s3 sync "s3://pytorch-backup/${package_name}-${promote_version}-pypi-staging/" "${TMP_DIR}/"
        ${TWINE_UPLOAD} --skip-existing "${TMP_DIR}/*.whl"
    )
}

promote_staging_binaries torch "${PYTORCH_VERSION}"
promote_staging_binaries torchvision "${TORCHVISION_VERSION}"
promote_staging_binaries torchaudio "${TORCHAUDIO_VERSION}"
promote_staging_binaries torchtext "${TORCHTEXT_VERSION}"
