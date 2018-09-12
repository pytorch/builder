#!/bin/bash

set -ex

# Update the html links file in the s3 bucket Pip uses this html file to look
# through all the wheels and pick the most recently uploaded one (by the
# version, not the actual date of upload). There is one html file per cuda/cpu
# version

# Upload for all CUDA/cpu versions if not given one to use
if [[ -z "$CUDA_VERSIONS" ]]; then
    export CUDA_VERSIONS=('cpu' 'cu80' 'cu90' 'cu92')
fi

if [[ -z "$PIP_UPLOAD_FOLDER" ]]; then
    export PIP_UPLOAD_FOLDER='nightly/'
fi

for cuda_ver in "${CUDA_VERSIONS[@]}"; do
    s3_dir="s3://pytorch/whl/${PIP_UPLOAD_FOLDER}${cuda_ver}/"

    # Pull all existing whls in this directory and turn them into html links
    # N.B. we use the .dev as a hacky way to exclude all wheels with old
    # 'yyyy.mm.dd' versions
    aws s3 ls "$s3_dir" | grep --only-matching '\S*\.dev\S*\.whl' | sed 's#.*#<a href="&"></a>#g' > ./torch_nightly.html

    # Check your work every once in a while
    echo 'Setting torch_nightly.html to:'
    cat ./torch_nightly.html

    # Upload the html file back up
    # Note the lack of a / b/c duplicate / do cause problems in s3
    aws s3 cp './torch_nightly.html' "${s3_dir}torch_nightly.html"  --acl public-read
done
