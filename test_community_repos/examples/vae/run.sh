#!/bin/bash -xe

BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone https://github.com/pytorch/examples.git
./download-data.sh
./install-deps.sh
./run-script.sh
RETURN=$?
rm -rf examples
popd
exit $RETURN

