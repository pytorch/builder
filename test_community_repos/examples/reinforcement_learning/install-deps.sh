#!/bin/bash -xe

pip install subprocess32

pushd examples/reinforcement_learning
pip install -r requirements.txt
popd
