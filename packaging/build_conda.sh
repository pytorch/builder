#!/bin/bash -xe

COMMAND_TO_WRAP=$1

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. "$script_dir/pkg_helpers.bash"

export BUILD_TYPE=conda
setup_env 0.5.0
export SOURCE_ROOT_DIR="$PWD"
setup_conda_pytorch_constraint
setup_conda_cudatoolkit_constraint


echo "Printing python version BEFORE Conda activation"
python --version

echo "About to run: source activate env$PYTHON_VERSION"
source activate "env$PYTHON_VERSION"


echo "Printing python version AFTER Conda activation"
python --version


if [ $CU_VERSION != 'cpu' ]
then

    if [ $CU_VERSION == '9.2' ]
    then
        conda install pytorch torchvision cudatoolkit=$CU_VERSION -c pytorch-nightly -c defaults -c numba/label/dev
    else
        conda install pytorch torchvision cudatoolkit=$CU_VERSION -c pytorch-nightly
    fi
else

    conda install pytorch torchvision cpuonly -c pytorch-nightly
fi



$COMMAND_TO_WRAP