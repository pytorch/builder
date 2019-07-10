#!/usr/bin/env bash

export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export USE_CUDA=0
export TH_BINARY_BUILD=1
export PYTORCH_BUILD_VERSION=$PKG_VERSION
export PYTORCH_BUILD_NUMBER=$PKG_BUILDNUM

if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOSX_DEPLOYMENT_TARGET=10.9 python setup.py install
else
    python setup.py install
fi
