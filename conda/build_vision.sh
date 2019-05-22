#!/usr/bin/env bash
if [[ -x "/remote/anaconda_token" ]]; then
    . /remote/anaconda_token || true
fi

set -e

ANACONDA_USER=pytorch
conda config --set anaconda_upload no

set -e
export TORCHVISION_BUILD_VERSION="0.3.0"
export TORCHVISION_BUILD_NUMBER=1


rm -rf torchvision-src
git clone https://github.com/pytorch/vision torchvision-src
pushd torchvision-src
git checkout v$TORCHVISION_BUILD_VERSION
popd

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters. Pass cuda version"
    echo "CUDA version should be M.m with no dot, e.g. '8.0' or 'cpu'"
    exit 1
fi
desired_cuda="$1"

export TORCHVISION_PACKAGE_SUFFIX=""
if [[ "$desired_cuda" == 'cpu' ]]; then
    export CONDA_CUDATOOLKIT_CONSTRAINT=""
    export CUDA_VERSION="None"
    if [[ "$OSTYPE" != "darwin"* ]]; then
        export TORCHVISION_PACKAGE_SUFFIX="-cpu"
    fi
else
    . ./switch_cuda_version.sh $desired_cuda
    if [[ "$desired_cuda" == "10.0" ]]; then
	export CONDA_CUDATOOLKIT_CONSTRAINT="    - cudatoolkit >=10.0,<10.1 # [not osx]"
    elif [[ "$desired_cuda" == "9.0" ]]; then
	export CONDA_CUDATOOLKIT_CONSTRAINT="    - cudatoolkit >=9.0,<9.1 # [not osx]"
    else
	echo "unhandled desired_cuda: $desired_cuda"
	exit 1
    fi
fi

time conda build -c $ANACONDA_USER --no-anaconda-upload --python 2.7 torchvision
time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.5 torchvision
time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.6 torchvision
time conda build -c $ANACONDA_USER --no-anaconda-upload --python 3.7 torchvision

set +e
