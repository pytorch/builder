#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone git@github.com:pytorch/botorch.git
pushd botorch


# ???
#pip install -e .[dev]

python setup.py test


popd
rm -rf botorch
popd

