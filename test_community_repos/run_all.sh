#!/bin/bash -xe

BASEDIR=$(dirname $0)
pushd $BASEDIR

python run_all.py

popd
