#!/bin/bash -xe

BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/skorch-dev/skorch.git
pushd skorch


python setup.py develop
py.test


popd
rm -rf skorch
popd

