#!/bin/bash

# Upload all the wheels and conda packages

set -ex

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)

today="/scratch/nightlies/$(date +%Y_%m_%d)"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
pushd "$today"

# Default parameters
if [[ -z "PIP_UPLOAD_FOLDER" ]]; then
    PIP_UPLOAD_FOLDER='nightly/'
fi
if [[ -z "$CUDA_VERSIONS" ]]; then
    export CUDA_VERSIONS=('cpu' 'cu80' 'cu90' 'cu92')
fi

# Upload wheels
"$SOURCE_DIR/../manywheel/upload.sh"

# Update wheel htmls
"$SOURCE_DIR/../update_s3_html.sh"

# TODO upload condas
