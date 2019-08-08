#!/bin/bash

set -e

# Take a package name + version and publish all matching packages
# from S3 production to PyPI

export SUBFOLDERS=('' 'cpu/' 'cu92/' 'cu100/')
s3_prod="s3://pytorch/whl/"

for subfolder in "${SUBFOLDERS[@]}"; do
  for file in $(aws s3 ls "$s3_prod$subfolder" | grep --only-matching '\S*\.whl' | grep "$1-\|$1+"); do
    aws s3 cp "$s3_prod$subfolder$file" "$file"
    twine upload -u ezyang "$file"
  done
done
