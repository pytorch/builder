#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Allow for users to pass PACKAGE_NAME

# For use with other packages, i.e. torchvision, etc.
PACKAGE_NAME=${PACKAGE_NAME:-torch}

PACKAGE_VERSION=${PACKAGE_VERSION:-1.0.0}
# Refers to the specific package we'd like to promote
# i.e. VERSION_SUFFIX='%2Bcu102'
#      torch-1.8.0+cu102 -> torch-1.8.0
VERSION_SUFFIX=${VERSION_SUFFIX:-}
# Refers to the specific platofmr we'd like to promote
# i.e. PLATFORM=linux_x86_64
# For domains like torchaudio / torchtext this is to be left blank
PLATFORM=${PLATFORM:-}
# Refers to the specific architecture we'd like to promote
# i.e. cpu, cu121, cu124
ARCH==${ARCH:-cpu}

pkgs_to_promote=$(\
    curl -fsSL "https://download.pytorch.org/whl/test/${ARCH}/${PACKAGE_NAME}/index.html" \
        | grep "${PACKAGE_NAME}-${PACKAGE_VERSION}${VERSION_SUFFIX}-" \
        | grep "${PLATFORM}" \
        | cut -d '"' -f2
)

tmp_dir="$(mktemp -d)"
output_tmp_dir="$(mktemp -d)"
trap 'rm -rf ${tmp_dir} ${output_tmp_dir}' EXIT
pushd "${output_tmp_dir}"

# Dry run by default
DRY_RUN=${DRY_RUN:-enabled}
# On dry run just echo the commands that are meant to be run
DRY_RUN_FLAG="--dryrun"
if [[ $DRY_RUN = "disabled" ]]; then
    DRY_RUN_FLAG=""
fi

for pkg in ${pkgs_to_promote}; do
    pkg_basename="$(basename "${pkg}")"

    if [[ "${pkg}" != *aarch64* && "${pkg}" != *torchao* ]]; then
        # sub out linux for manylinux1
        pkg_basename="$(basename "${pkg//linux/manylinux1}")"
    elif [[ "${pkg}" == *manylinux_2_17_aarch64* ]]; then
        # strip manylinux_2_17 from core filename
        pkg_basename="$(basename "${pkg//manylinux_2_17_aarch64./}")"
    elif [[ "${pkg}" == *linux_aarch64* ]]; then
        # domains change linux_aarch64 to manylinux2014_aarch64
        pkg_basename="$(basename "${pkg//linux_aarch64/manylinux2014_aarch64}")"
    fi

    orig_pkg="${tmp_dir}/${pkg_basename}"
    (
        set -x
        curl -fSL -o "${orig_pkg}" "https://download.pytorch.org${pkg}"
    )

    if [[ -n "${VERSION_SUFFIX}" ]]; then
        OUTPUT_DIR="${output_tmp_dir}" bash "${DIR}/prep_binary_for_pypi.sh" "${orig_pkg}"
    else
        mv "${orig_pkg}" "${output_tmp_dir}/"
    fi

    (
        set -x
        aws s3 cp ${DRY_RUN_FLAG} *.whl "s3://pytorch-backup/${PACKAGE_NAME}-${PACKAGE_VERSION}-pypi-staging/"
        rm -rf ./*.whl
    )
done
