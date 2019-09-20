#!/bin/bash -xe

pip install syft

BASEDIR=$(dirname $0)
pushd $BASEDIR



git clone git@github.com:OpenMined/PySyft.git
pushd PySyft

make notebook


#../download_data.sh
#../install-deps.sh
#../run-script.sh
popd
rm -rf PySyft
popd

