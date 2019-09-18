#!/bin/bash -xe

pip install subprocess32

pushd examples/dcgan
pip install -r requirements.txt
popd
