#!/bin/bash -xe

CUDA_ARG=$1

pushd examples/word_language_model
# smoke tests
python main.py $CUDA_ARG --epochs 1
python main.py $CUDA_ARG --epochs 1 --tied
RETURN_CODE=$?
popd
exit $RETURN_CODE

