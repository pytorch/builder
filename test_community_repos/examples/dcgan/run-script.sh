#!/bin/bash -xe

CUDA_ARG=$1

pushd examples/dcgan
# smoke test
python main.py --dataset fake --dataroot . $CUDA_ARG --niter 100
RETURN_CODE=$?
popd
exit $RETURN_CODE

