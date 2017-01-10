#!/usr/bin/env bash
set -e

if [ -z "$ANACONDA_TOKEN" ]; then
    echo "ANACONDA_TOKEN is unset. Please set it in your environment before running this script";
    exit 1
fi

BUILD_VERSION="0.1.6"
BUILD_NUMBER=13


rm -rf pytorch-src
git clone https://github.com/pytorch/pytorch pytorch-src
pushd pytorch-src
git checkout v$BUILD_VERSION
popd

rm -rf torchvision-src
git clone https://github.com/pytorch/vision torchvision-src
pushd torchvision-src
git checkout v$BUILD_VERSION
popd

export PYTORCH_BUILD_VERSION=$BUILD_VERSION
export PYTORCH_BUILD_NUMBER=$BUILD_NUMBER

conda config --set anaconda_upload no

time conda build --no-anaconda-upload --python 2.7 pytorch-$BUILD_VERSION
time conda build --no-anaconda-upload --python 3.5 pytorch-$BUILD_VERSION

time conda build --no-anaconda-upload --python 2.7 torchvision-$BUILD_VERSION
time conda build --no-anaconda-upload --python 3.5 torchvision-$BUILD_VERSION

echo "All builds succeeded, uploading binaries"

set +e

anaconda -t $ANACONDA_TOKEN upload --user soumith $(conda build --python 2.7 pytorch-$BUILD_VERSION --output)
anaconda -t $ANACONDA_TOKEN upload --user soumith $(conda build --python 3.5 pytorch-$BUILD_VERSION --output)

anaconda -t $ANACONDA_TOKEN upload --user soumith $(conda build --python 2.7 torchvision-$BUILD_VERSION --output)
anaconda -t $ANACONDA_TOKEN upload --user soumith $(conda build --python 3.5 torchvision-$BUILD_VERSION --output)

unset PYTORCH_BUILD_VERSION
unset PYTORCH_BUILD_NUMBER
