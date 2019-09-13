#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


# Testing instructions taken from here:
# https://github.com/williamFalcon/pytorch-lightning/tree/master/tests#pytorch-lightning-tests
git clone https://github.com/williamFalcon/pytorch-lightning.git
pushd pytorch-lightning

# install module locally
pip install -e .

# install dev deps
pip install -r requirements.txt

# run tests
py.test -v

popd
rm -rf pytorch-lightning
popd

