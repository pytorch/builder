#!/usr/bin/env bash
. /remote/anaconda_token || true

set -e

if [ -z "$ANACONDA_TOKEN" ]; then
    echo "ANACONDA_TOKEN is unset. Please set it in your environment before running this script";
    exit 1
fi

BUILD_VERSION="0.2.0"
BUILD_NUMBER=4

ANACONDA_USER=soumith
rm -rf pytorch-src
git clone https://github.com/pytorch/pytorch pytorch-src
pushd pytorch-src
git checkout v$BUILD_VERSION
popd

export PYTORCH_BUILD_VERSION=$BUILD_VERSION
export PYTORCH_BUILD_NUMBER=$BUILD_NUMBER

conda config --set anaconda_upload no

if [[ "$OSTYPE" == "darwin"* ]]; then

    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 pytorch-$BUILD_VERSION
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 pytorch-$BUILD_VERSION
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 pytorch-$BUILD_VERSION    
else
    ./switch_cuda_version.sh 7.5
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 pytorch-$BUILD_VERSION
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 pytorch-$BUILD_VERSION
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 pytorch-$BUILD_VERSION    

    ./switch_cuda_version.sh 8.0

    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 pytorch-cuda80-$BUILD_VERSION
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 pytorch-cuda80-$BUILD_VERSION
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 pytorch-cuda80-$BUILD_VERSION    

    ./switch_cuda_version.sh 7.5 # restore
fi

echo "All builds succeeded, uploading binaries"

set +e

anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 2.7 pytorch-$BUILD_VERSION --output)
anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 3.5 pytorch-$BUILD_VERSION --output)
anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 3.6 pytorch-$BUILD_VERSION --output)
if [[ "$OSTYPE" == "linux"* ]]; then
    anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 2.7 pytorch-cuda80-$BUILD_VERSION --output)
    anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 3.5 pytorch-cuda80-$BUILD_VERSION --output)
    anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 3.6 pytorch-cuda80-$BUILD_VERSION --output)
fi

unset PYTORCH_BUILD_VERSION
unset PYTORCH_BUILD_NUMBER
