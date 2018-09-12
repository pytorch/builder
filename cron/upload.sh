#!/bin/bash

set -ex
echo "upload.sh at $(pwd) starting at $(date) on $(uname -a)"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Upload all the wheels and conda packages.
# NIGHTLIES_DATE
#   Switch the date from the default 'today' to any past date, in YYYY-mm-dd
# PIP_UPLOAD_FOLDER
#   For now this has to be nightly/ or something non-empty. Originally, the
#   empty string was used to denote uploading to the original packages (the non
#   nightly packages) where e.g. torch-0.4.1 live. This was dangerous and easy
#   to accidentally do however, so right now the empty string is not allowed
# CUDA_VERSIONS
#   Which package folders to upload. In [cpu, cu80, cu90, cu92]

# Default parameters
if [[ -z "$CUDA_VERSIONS" ]]; then
    export CUDA_VERSIONS=('cpu' 'cu80' 'cu90' 'cu92')
fi

if [[ "$(uname)" == 'Darwin' ]]; then
    # Upload everything
    "${NIGHTLIES_BUILDER_ROOT}/wheel/upload.sh"
else
    # Upload wheels
    # manywheel/upload.sh looks in the current directory for wheelhousecpu/ etc
    pushd "$today"
    "${NIGHTLIES_BUILDER_ROOT}/manywheel/upload.sh"
    popd

    # TODO upload condas
fi

# Update wheel htmls
"${NIGHTLIES_BUILDER_ROOT}/update_s3_htmls.sh"
