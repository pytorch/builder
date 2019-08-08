#!/bin/bash

set -e

# Take a package name + version and publish all matching packages
# (also including local version specifiers) from nightly/ to /
#
# Does NOT update HTMLs; run that command afterwards

export SUBFOLDERS=('' 'cpu/' 'cu92/' 'cu100/')
s3_prod="s3://pytorch/whl/"
s3_nightly="s3://pytorch/whl/nightly/"

for subfolder in "${SUBFOLDERS[@]}"; do
  for file in $(aws s3 ls "$s3_nightly$subfolder" | grep --only-matching '\S*\.whl' | grep "$1-\|$1+"); do
    aws s3 cp "$s3_nightly$subfolder$file" "$s3_prod$subfolder$(echo "$file" | sed 's/-linux/-manylinux1/')"
  done
done
