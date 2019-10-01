#!/bin/bash -xe

BASEDIR=$(dirname $0)
pushd $BASEDIR

./run_all.py

popd
