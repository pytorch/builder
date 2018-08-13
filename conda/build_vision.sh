#!/usr/bin/env bash
. /remote/anaconda_token || true

set -e

if [ -z "$ANACONDA_TOKEN" ]; then
    echo "ANACONDA_TOKEN is unset. Please set it in your environment before running this script";
    exit 1
fi

ANACONDA_USER=pytorch
conda config --set anaconda_upload no

set -e
VISION_BUILD_VERSION="0.2.1"
VISION_BUILD_NUMBER=1

rm -rf torchvision-src
git clone https://github.com/pytorch/vision torchvision-src
pushd torchvision-src
git checkout v$VISION_BUILD_VERSION
popd

export PYTORCH_VISION_BUILD_VERSION=$VISION_BUILD_VERSION
export PYTORCH_VISION_BUILD_NUMBER=$VISION_BUILD_NUMBER

# time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 torchvision-$VISION_BUILD_VERSION
# time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 torchvision-$VISION_BUILD_VERSION
# time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 torchvision-$VISION_BUILD_VERSION
time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.7 torchvision-$VISION_BUILD_VERSION

# time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 torchvision-cpu-$VISION_BUILD_VERSION
# time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 torchvision-cpu-$VISION_BUILD_VERSION
# time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 torchvision-cpu-$VISION_BUILD_VERSION
time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.7 torchvision-cpu-$VISION_BUILD_VERSION

set +e


unset PYTORCH_BUILD_VERSION
unset PYTORCH_BUILD_NUMBER
unset PYTORCH_VISION_BUILD_VERSION
unset PYTORCH_VISION_BUILD_NUMBER
