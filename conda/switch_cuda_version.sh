#!/bin/bash
set -ex -o pipefail

if [[ "$OSTYPE" == "msys" ]]; then
    CUDA_DIR="/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v$1"
else
    CUDA_DIR="/usr/local/cuda-$1"
fi

if ! ls "$CUDA_DIR"
then
    echo "folder $CUDA_DIR not found to switch"
fi

echo "Switching symlink to $CUDA_DIR"
mkdir -p /usr/local
rm -fr /usr/local/cuda
ln -s "$CUDA_DIR" /usr/local/cuda

# Using nvcc instead of deducing from cudart version since it's unreliable (was 110 for cuda11.1 and 11.2)
CUDA_VERSION_DOT=$(nvcc --version | sed -n 4p | cut -f5 -d" " | cut -f1 -d",")
export CUDA_VERSION=${CUDA_VERSION_DOT/./}
if [[ "$OSTYPE" == "msys" ]]; then
    # we want CUDNN_VERSION=8.1 for CUDA 11.2, not just 8
    if [[ "$CUDA_VERSION" == '112' ]]; then
        CUDNN_MAJOR=$(find /usr/local/cuda/ -name cudnn_version.h -exec grep 'define CUDNN_MAJOR' {} + | cut -d' ' -f3)
        CUDNN_MINOR=$(find /usr/local/cuda/ -name cudnn_version.h -exec grep 'define CUDNN_MINOR' {} + | cut -d' ' -f3)
        CUDNN_VERSION=$CUDNN_MAJOR.$CUDNN_MINOR
    else
        CUDNN_VERSION=$(find /usr/local/cuda/bin/cudnn64*.dll | head -1 | tr '._' ' ' | cut -d ' ' -f2)
    fi
else
    CUDNN_VERSION=$(find /usr/local/cuda/lib64/libcudnn.so.* | sort | tac | head -1 | rev | cut -d"." -f -3 | rev)
fi
export CUDNN_VERSION

ls -alh /usr/local/cuda

echo "CUDA_VERSION=$CUDA_VERSION"
echo "CUDNN_VERSION=$CUDNN_VERSION"
