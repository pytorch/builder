#!/usr/bin/env bash
. /remote/anaconda_token || true

set -e

echo "Building cuda version $1"

if [ -z "$ANACONDA_TOKEN" ]; then
    echo "ANACONDA_TOKEN is unset. Please set it in your environment before running this script";
    exit 1
fi

BUILD_VERSION="0.3.0"
BUILD_NUMBER=3

ANACONDA_USER=pytorch
rm -rf pytorch-src
git clone https://github.com/pytorch/pytorch pytorch-src --recursive
pushd pytorch-src
git checkout v$BUILD_VERSION
popd

export PYTORCH_BUILD_VERSION=$BUILD_VERSION
export PYTORCH_BUILD_NUMBER=$BUILD_NUMBER

conda config --set anaconda_upload no

if [[ "$OSTYPE" == "darwin"* ]]; then
    export CUDA_VERSION="0.0"
    export CUDNN_VERSION="0.0"
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 pytorch-$BUILD_VERSION
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 pytorch-$BUILD_VERSION
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 pytorch-$BUILD_VERSION
else
    if [[ "$1" == "80"]]; then
	. ./switch_cuda_version.sh 8.0
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 pytorch-$BUILD_VERSION
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 pytorch-$BUILD_VERSION
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 pytorch-$BUILD_VERSION
    elif [[ "$1" == "90"]]; then
	. ./switch_cuda_version.sh 9.0
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 pytorch-cuda90-$BUILD_VERSION
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 pytorch-cuda90-$BUILD_VERSION
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 pytorch-cuda90-$BUILD_VERSION
	
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 pytorch-cuda90-nccl2-$BUILD_VERSION
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 pytorch-cuda90-nccl2-$BUILD_VERSION
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 pytorch-cuda90-nccl2-$BUILD_VERSION
    elif [[ "$1" == "75"]]; then
	. ./switch_cuda_version.sh 7.5
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 pytorch-cuda75-$BUILD_VERSION
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 pytorch-cuda75-$BUILD_VERSION
	time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 pytorch-cuda75-$BUILD_VERSION
    else
	echo "Error, unknown argument $1"
	exit 1
    fi
fi

echo "All builds succeeded, uploading binaries"

set +e

# anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 2.7 pytorch-$BUILD_VERSION --output)
# anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 3.5 pytorch-$BUILD_VERSION --output)
# anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 3.6 pytorch-$BUILD_VERSION --output)

unset PYTORCH_BUILD_VERSION
unset PYTORCH_BUILD_NUMBER
