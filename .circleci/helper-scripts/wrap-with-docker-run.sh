#!/bin/bash -xe

COMMAND_TO_WRAP=$1

conda env remove -n "env$PYTHON_VERSION" || true
conda create -yn "env$PYTHON_VERSION" python="$PYTHON_VERSION"

source activate "env$PYTHON_VERSION"

$COMMAND_TO_WRAP
