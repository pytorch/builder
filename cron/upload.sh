#!/bin/bash

set -ex
echo "upload.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Upload all nightly packages.
# This has two use cases:
# In the regular nightlies use-case this script is passed all the succesfull
# logs
#   ./cron/upload.sh conda_2.7_cpu.log manywheel_2.7mu_cu80.log ...
# and only those corresponding packages are uploaded.
# Otherwise, if given no parameters this will upload all packages.

upload_it () {
    pkg_type="$1"
    cuda_ver="$2"
    pkg="$3"

    if [[ "$pkg_type" == 'conda' ]]; then
        echo "Uploading $pkg to anaconda"
        anaconda upload "$pkg" -u pytorch --label main --force
    elif [[ "$pkg_type" == 'libtorch' ]]; then
        s3_dir="s3://pytorch/libtorch/${PIP_UPLOAD_FOLDER}${cuda_ver}/"
        echo "Uploading $pkg to $s3_dir"
        aws s3 cp "$pkg" "$s3_dir" --acl public-read --quiet
    else
        uploaded_a_wheel=1
        s3_dir="s3://pytorch/whl/${PIP_UPLOAD_FOLDER}${cuda_ver}/"
        echo "Uploading $pkg to $s3_dir"
        aws s3 cp "$pkg" "$s3_dir" --acl public-read --quiet
    fi
}

# Set-up tools we need to upload
##############################################################################
# Source the credentials if given
if [[ -x "$PYTORCH_CREDENTIALS_FILE" ]]; then
    source "$PYTORCH_CREDENTIALS_FILE"
fi

# This needs both 'aws' and 'anaconda-client', so if a conda installation is
# not active then we download a new one and install what we need
# Download miniconda so that we can install aws and anaconda-client on it
set +e
conda --version
ret="$?"
aws --version
ret1="$?"
anaconda upload -h >/dev/null
ret2="$?"
set -e
if [[ "$ret" -ne 0 || "$ret1" -ne 0 || "$ret2" -ne 0 ]]; then
    tmp_conda="${today}/miniconda"
    miniconda_sh="${today}/miniconda.sh"
    if [[ "$(uname)" == 'Darwin' ]]; then
        curl https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o "$miniconda_sh"
    else
        curl https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o "$miniconda_sh"
    fi
    chmod +x "$miniconda_sh" && \
        "$miniconda_sh" -b -p "$tmp_conda" && \
        rm "$miniconda_sh"
    export PATH="$tmp_conda/bin:$PATH"

    # Install aws and anaconda client
    pip install awscli
    conda install -y anaconda-client
    yes | anaconda login --username "$PYTORCH_ANACONDA_USERNAME" --password "$PYTORCH_ANACONDA_PASSWORD"
fi

# Loop through all packages to upload
##############################################################################
# If given package types, then only upload those package types
packages_to_upload=()
if [[ "$#" -eq 0 ]]; then
    # If not given any specific packages to upload, then upload everything that
    # we can find
    # Packages are organized by type and CUDA/cpu version so we have to loop
    # over these to find all the packages
    _ALL_PKG_TYPES=("manywheel" "wheel" "conda" "libtorch")
    _ALL_CUDA_VERSIONS=("cpu" "cu80" "cu90" "cu92")
    for pkg_type in "${_ALL_PKG_TYPES[@]}"; do
        for cuda_ver in "${_ALL_CUDA_VERSIONS[@]}"; do
            pkg_dir="$(nightlies_package_folder $pkg_type $cuda_ver)"
            if [[ ! -d "$pkg_dir" ]]; then
                continue
            fi
            for pkg in $pkg_dir/*; do
                upload_it "$pkg_type" "$cuda_ver" "$pkg"
            done
        done
    done
else
    # Else we're given a bunch of log names, turn these into exact packages
    # Remove all '.log's from the names
    all_configs=()
    while [[ $# -gt 0 ]]; do
        IFS=, confs=($(basename $1 .log | tr '_' ','))
        pkg_type="${confs[0]}"
        py_ver="${confs[1]}"
        cuda_ver="${confs[2]}"
        pkg_dir="$(nightlies_package_folder $pkg_type $cuda_ver)"

        # Map e.g. 2.7mu -> cp27mu
        if [[ "${#py_ver}" -gt 3 ]]; then
            if [[ "$py_ver" == '2.7mu' ]]; then
                py_ver="cp27mu"
            else
                py_ver="cp${py_ver:0:1}${py_ver:2:1}m"
            fi
        fi

        if [[ "$pkg_type" == 'libtorch' ]]; then
            # Libtorch builds create a lot of different variants for each cuda
            # version and ignores the python version. The package dir in this
            # case will contain shared/static with/without deps. We just upload
            # all the packages we find
            for pkg in $pkg_dir/*; do
                upload_it 'libtorch' "$cuda_ver" "$pkg"
            done
        else
            # Conda/wheel/manywheel - Find the exact package to upload
            # This package dir contains packages of different python versions,
            # some of which may have failed tests. We need to find the exact
            # python version that succeeded to upload.
            # We need to match - or _ after the python version to avoid
            # matching cp27mu when we're trying to mach cp27m. TODO this will
            # only work when the name in both conda and wheel packages does
            # follow the python version with a - or _
            set +e
            unset pkg
            pkg="$(ls $pkg_dir | grep $py_ver[-_])"
            set -e
            if [[ -n "$pkg" ]]; then
                upload_it "$pkg_type" "$cuda_ver" "$pkg_dir/$pkg"
            else
                echo "!!WARNING!! Could not find the package for $1. I looked for"
                echo "!!WARNING!! python version $py_ver in $pkg_dir but couldn't"
                echo "!!WARNING!! find anything"
            fi
        fi
        shift
    done
fi

# Update wheel htmls
"${NIGHTLIES_BUILDER_ROOT}/update_s3_htmls.sh"
