#!/bin/bash -xe

pushd examples/fast_neural_style

# TODO EXPERIMENTAL
echo "Current dir"
pwd

echo "Current dir contents"
ls -l

pip install -r requirements.txt
popd
