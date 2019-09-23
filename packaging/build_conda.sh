#!/bin/bash -xe

COMMAND_TO_WRAP=$1

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. "$script_dir/pkg_helpers.bash"

export BUILD_TYPE=conda
setup_env 0.5.0
export SOURCE_ROOT_DIR="$PWD"
setup_conda_pytorch_constraint
setup_conda_cudatoolkit_constraint
#conda build $CONDA_CHANNEL_FLAGS -c defaults -c conda-forge --no-anaconda-upload --python "$PYTHON_VERSION" packaging/torchvision


echo "Printing python version BEFORE Conda activation"
python --version

echo "About to run: source activate env$PYTHON_VERSION"
source activate "env$PYTHON_VERSION"


echo "Printing python version AFTER Conda activation"
python --version


$COMMAND_TO_WRAP