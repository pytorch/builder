#!/bin/bash

set -e

# Update the html links file in the s3 bucket Pip uses this html file to look
# through all the wheels and pick the most recently uploaded one (by the
# version, not the actual date of upload). There is one html file per cuda/cpu
# version

# Upload for all CUDA/cpu versions if not given one to use
if [[ -z "$CUDA_VERSIONS" ]]; then
    export CUDA_VERSIONS=('cpu' 'cu92' 'cu100' 'cu101' 'cu102' 'cu110' 'rocm4.5.2' 'rocm5.0')
fi

if [[ -z "$HTML_NAME" ]]; then
    export HTML_NAME='torch_nightly.html'
fi

# Dry run disabled by default for legacy purposes
DRY_RUN=${DRY_RUN:-disabled}
DRY_RUN_FLAG=""
if [[ "${DRY_RUN}" != disabled ]]; then
  DRY_RUN_FLAG="--dryrun"
fi

# NB: includes trailing slash (from PIP_UPLOAD_FOLDER)
s3_base="s3://pytorch/whl/${PIP_UPLOAD_FOLDER}"

# Pull all existing whls in this directory and turn them into html links
# N.B. we use the .dev as a hacky way to exclude all wheels with old
# 'yyyy.mm.dd' versions
#
# NB: replacing + with %2B is to fix old versions of pip which don't
# this transform automatically.  This makes the display a little
# ugly but whatever
function generate_html() {
  # Trailing slash required in both cases
  dir="$1"
  url_prefix="$2"
  aws s3 ls "${s3_base}${dir}" | grep --only-matching '\S*\.whl' | sed 's#+#%2B#g' | sed 's#.*#<a href="'"${url_prefix}"'&">'"${url_prefix}"'&</a><br>#g'
}

# This will be included in all the sub-indices
generate_html '' '../' > "root-$HTML_NAME"
generate_html '' '' > "$HTML_NAME"

for cuda_ver in "${CUDA_VERSIONS[@]}"; do
    generate_html "${cuda_ver}/" "" > "${cuda_ver}-$HTML_NAME"
    cat "root-$HTML_NAME" >> "${cuda_ver}-$HTML_NAME"
    generate_html "${cuda_ver}/" "${cuda_ver}/" >> "$HTML_NAME"

    # Check your work every once in a while
    echo "Setting ${cuda_ver}/$HTML_NAME to:"
    cat "${cuda_ver}-$HTML_NAME"
    (
      set -x
      aws s3 cp ${DRY_RUN_FLAG} "${cuda_ver}-$HTML_NAME" "s3://pytorch/whl/${PIP_UPLOAD_FOLDER}${cuda_ver}/$HTML_NAME"  --acl public-read --cache-control 'no-cache,no-store,must-revalidate'
    )

done

# Check your work every once in a while
echo "Setting $HTML_NAME to:"
cat "$HTML_NAME"
(
  set -x

  # Upload the html file back up
  # Note the lack of a / b/c duplicate / do cause problems in s3
  aws s3 cp ${DRY_RUN_FLAG} "$HTML_NAME" "$s3_base$HTML_NAME"  --acl public-read --cache-control 'no-cache,no-store,must-revalidate'
)
