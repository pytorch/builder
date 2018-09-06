#!/bin/bash

# Upload all the wheels and conda packages.
# UPLOAD_DATE
#   Switch the date from the default 'today' to any past date, in YYYY-mm-dd
# PIP_UPLOAD_FOLDER
#   For now this has to be nightly/ or something non-empty. Originally, the
#   empty string was used to denote uploading to the original packages (the non
#   nightly packages) where e.g. torch-0.4.1 live. This was dangerous and easy
#   to accidentally do however, so right now the empty string is not allowed
# CUDA_VERSIONS
#   Which package folders to upload. In [cpu, cu80, cu90, cu92]

set -ex

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)

if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    NIGHTLIES_FOLDER='/scratch/hellemn/nightlies/'
fi
if [[ -z "$UPLOAD_DATE" ]]; then
    UPLOAD_DATE="$(date +%Y_%m_%d)"
fi
# N.B there is NO / HERE. Because s3 is not real folders, just filenames with /
# in them
today="$NIGHTLIES_FOLDER$UPLOAD_DATE"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
pushd "$today"

# Default parameters
if [[ -z "$PIP_UPLOAD_FOLDER" ]]; then
    export PIP_UPLOAD_FOLDER='nightly/'
fi
if [[ -z "$CUDA_VERSIONS" ]]; then
    export CUDA_VERSIONS=('cpu' 'cu80' 'cu90' 'cu92')
fi

# Upload wheels
"$SOURCE_DIR/../manywheel/upload.sh"

# Update wheel htmls
"$SOURCE_DIR/../update_s3_htmls.sh"

# TODO upload condas
