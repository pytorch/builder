#!/bin/bash -xe

COMMAND_TO_WRAP=$1
CONDA_ACTIVATION_WRAPPER_SCRIPT=.circleci/helper-scripts/wrap-with-conda-activation.sh

cd ${HOME}/project

export DOCKER_IMAGE=soumith/conda-cuda
export VARS_TO_PASS="-e PYTHON_VERSION -e BUILD_VERSION -e PYTORCH_VERSION -e UNICODE_ABI -e CU_VERSION"

docker run --gpus all --ipc=host -v $(pwd):/remote -w /remote ${VARS_TO_PASS} ${DOCKER_IMAGE} $CONDA_ACTIVATION_WRAPPER_SCRIPT $COMMAND_TO_WRAP

