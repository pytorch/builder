#!/bin/bash -xe

COMMAND_TO_WRAP=$1

cd ${HOME}/project

export DOCKER_IMAGE=soumith/conda-cuda
export VARS_TO_PASS="-e PYTHON_VERSION -e BUILD_VERSION -e PYTORCH_VERSION -e UNICODE_ABI -e CU_VERSION"

docker run --gpus all  --ipc=host -v $(pwd):/remote -w /remote ${VARS_TO_PASS} ${DOCKER_IMAGE} $COMMAND_TO_WRAP
