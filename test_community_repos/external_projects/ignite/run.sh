#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone git@github.com:pytorch/ignite.git
pushd ignite


python setup.py test


popd
rm -rf ignite
popd

