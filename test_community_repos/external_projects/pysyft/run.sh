#!/bin/bash -xe

yes | pip install pytest tblib websocket websockets lz4 msgpack zstd scipy torch


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/OpenMined/PySyft.git
pushd PySyft

pytest test/torch


popd
rm -rf PySyft
popd

