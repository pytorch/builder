#!/bin/bash

set -ex
echo "upload.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Upload all the wheels and conda packages.

# If given package types, then only upload those package types
if [[ "$#" -eq 0 ]]; then
    upload_wheels=1
    upload_condas=1
else
    upload_wheels=0
    upload_condas=0
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == *wheel* ]]; then
            upload_wheels=1
        fi
        if [[ "$1" == *conda* ]]; then
            upload_condas=1
        fi
        shift
    done
fi


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
    anaconda login --username "$PYTORCH_ANACONDA_USERNAME" --password "$PYTORCH_ANACONDA_PASSWORD"
fi


# Upload wheels
if [[ "$upload_wheels" == 1 ]]; then
    if [[ "$(uname)" == 'Darwin' ]]; then
        "${NIGHTLIES_BUILDER_ROOT}/wheel/upload.sh"
    else
        PACKAGE_ROOT_DIR="$today" "${NIGHTLIES_BUILDER_ROOT}/manywheel/upload.sh"
    fi

    # Update wheel htmls
    "${NIGHTLIES_BUILDER_ROOT}/update_s3_htmls.sh"
fi

# Upload conda packages
if [[ "$upload_condas" == 1 ]]; then
    "${NIGHTLIES_BUILDER_ROOT}/conda/upload.sh"
fi
