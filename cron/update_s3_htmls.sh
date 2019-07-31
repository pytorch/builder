#!/bin/bash

set -ex

# Update the html links file in the s3 bucket Pip uses this html file to look
# through all the wheels and pick the most recently uploaded one (by the
# version, not the actual date of upload). There is one html file per cuda/cpu
# version

if [[ -z "$HTML_NAME" ]]; then
    export HTML_NAME='torch_nightly.html'
fi

s3_dir="s3://pytorch/whl/${PIP_UPLOAD_FOLDER}/"

# Pull all existing whls in this directory and turn them into html links
# N.B. we use the .dev as a hacky way to exclude all wheels with old
# 'yyyy.mm.dd' versions
#
# NB: replacing + with %2B is to fix old versions of pip which don't
# this transform automatically.  This makes the display a little
# ugly but whatever
aws s3 ls "$s3_dir" | grep --only-matching '\S*\.whl' | sed 's#+#%2B#g' | sed 's#.*#<a href="&">&</a><br>#g' > ./$HTML_NAME

# Check your work every once in a while
echo "Setting $HTML_NAME to:"
cat ./$HTML_NAME

# Upload the html file back up
# Note the lack of a / b/c duplicate / do cause problems in s3
aws s3 cp ./$HTML_NAME "${s3_dir}$HTML_NAME"  --acl public-read --cache-control 'no-cache,no-store,must-revalidate'
