#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/OpenMined/PySyft.git
pushd PySyft

pytest test/torch


popd
rm -rf PySyft
popd

