#!/bin/bash

# adhoc script that's useful to keep around to modify to move stuff around in s3

set -ex

CUDA_VERSIONS=('cpu') # 'cu80' 'cu90' 'cu92')
MAC_PY_VERSIONS=('27' '35' '36' '37')

full_root=/scratch/hellemn/nightlies/full/
old_root=/scratch/hellemn/nightlies/old/
today=2018.9.7

for cuda_ver in "${CUDA_VERSIONS[@]}"; do
  s3_full="s3://pytorch/whl/nightly/${cuda_ver}"
  local_old="${old_root}/${cuda_ver}/"
  local_full="${full_root}/${cuda_ver}/"
  for py in "${MAC_PY_VERSIONS[@]}"; do
    s3_old="s3://pytorch//private/var/lib/jenkins/workspace/pip-packages/pip-cp${py}-cp${py}m-macos10.13-build-upload/final_wheel/nightly/cpu/"

    mkdir -p "$local_old"
    mkdir -p "$local_full"

    # Copy all the files locally
     #aws s3 ls "$s3_old" | grep --only-matching "\S*${today}\S*\.whl" | xargs -I {} aws s3 cp "$s3_old"{} "${local_old}"{}
    # aws s3 ls "$s3_full" | grep --only-matching "\S*${today}\S*\.whl" | xargs -I {} aws s3 cp "$s3_full"{} "${local_full}"{}

    # Upload the files back to opposite folders
    # ls "$local_full" | xargs -I {} aws s3 cp "$local_full"{} "$s3_old"{} --acl public-read
     ls "$local_old" | xargs -I {} aws s3 cp "$local_old"/{} "$s3_full"/ --acl public-read

    # Delete erroneous old uploads
    #ls "$old" | xargs -I {} aws s3 rm  "$s3_old_bad"{}
  done
done


