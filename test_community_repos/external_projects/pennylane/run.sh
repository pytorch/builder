#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/XanaduAI/pennylane.git
pushd pennylane


python setup.py test


popd
rm -rf pennylane
popd

