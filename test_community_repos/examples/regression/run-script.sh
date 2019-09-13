#!/bin/bash -xe

pushd examples/regression
python main.py
RETURN_CODE=$?
popd
exit $RETURN_CODE

