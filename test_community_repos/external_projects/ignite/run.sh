#!/bin/bash -xe

yes | pip install pytest sklearn mock


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/pytorch/ignite.git
pushd ignite


python setup.py test


popd
rm -rf ignite
popd

