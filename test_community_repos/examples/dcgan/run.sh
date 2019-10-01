#!/bin/bash -xe

if [ $CU_VERSION != 'cpu' ]
then
    CUDA_ARG="--cuda"
fi

BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone https://github.com/pytorch/examples.git
./download-data.sh
./install-deps.sh
./run-script.sh $CUDA_ARG
RETURN=$?
rm -rf examples
popd
exit $RETURN

