#!/bin/bash -xe

BASEDIR=$(dirname $0)
pushd $BASEDIR

git clone https://github.com/OpenNMT/OpenNMT-py.git
pushd OpenNMT-py
../install-deps.sh
../run-script.sh
popd
rm -rf OpenNMT-py

popd

