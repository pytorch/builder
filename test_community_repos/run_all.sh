#!/bin/bash -xe

BASEDIR=$(dirname $0)
pushd $BASEDIR

python3 run_all.py

popd
