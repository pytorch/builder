#!/bin/bash -xe

COMMAND_TO_WRAP=$1

conda env remove -n "env$PYTHON_VERSION" || true
conda create -yn "env$PYTHON_VERSION" python="$PYTHON_VERSION"

source activate "env$PYTHON_VERSION"




if [ $CU_VERSION != 'cpu' ]
then

    if [ $CU_VERSION == '9.2' ]
    then
        conda install pytorch torchvision -c pytorch-nightly -c defaults -c numba/label/dev
    else
        conda install pytorch torchvision -c pytorch-nightly
    fi
else

    conda install pytorch torchvision cpuonly -c pytorch-nightly
fi




$COMMAND_TO_WRAP
