#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/cornellius-gp/gpytorch.git
pushd gpytorch


python -m unittest


popd
rm -rf gpytorch
popd

