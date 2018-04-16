#!/usr/bin/env bash
. /remote/anaconda_token || true

set -e

if [ -z "$ANACONDA_TOKEN" ]; then
    echo "ANACONDA_TOKEN is unset. Please set it in your environment before running this script";
    exit 1
fi

export FAISS_BUILD_VERSION="0.1"
export FAISS_BUILD_NUMBER=1

ANACONDA_USER=pytorch
rm -rf faiss-src
git clone https://github.com/facebookresearch/faiss faiss-src --recursive
pushd faiss-src
git checkout master
popd

conda config --set anaconda_upload no

if [[ "$OSTYPE" == "darwin"* ]]; then
    export CUDA_VERSION="0.0"
    export CUDNN_VERSION="0.0"
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 faiss-cpu
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 faiss-cpu
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 faiss-cpu
else
    export CUDA_VERSION="0.0"
    export CUDNN_VERSION="0.0"
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 faiss-cpu
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 faiss-cpu
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 faiss-cpu

    . ./switch_cuda_version.sh 8.0
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 faiss-gpu
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 faiss-gpu
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 faiss-gpu

    . ./switch_cuda_version.sh 9.0
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 faiss-gpu-cuda90
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 faiss-gpu-cuda90
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 faiss-gpu-cuda90

    . ./switch_cuda_version.sh 9.1
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 faiss-gpu-cuda91
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 faiss-gpu-cuda91
    time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 faiss-gpu-cuda91
fi

echo "All builds succeeded"
