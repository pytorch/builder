#!/usr/bin/env bash
set -e

if [ "$#" -ne 3 ]; then
    echo "illegal number of parameters. Need PY_VERSION BUILD_VERSION BUILD_NUMBER"
    echo "for example: build_wheel.sh 2 0.1.6 20"
    exit 1
fi

PYTHON_VERSION=$1
BUILD_VERSION=$2
BUILD_NUMBER=$3

echo "Building for Python: $PYTHON_VERSION Version: $BUILD_VERSION Build: $BUILD_NUMBER"

export PYTORCH_BUILD_VERSION=$BUILD_VERSION
export PYTORCH_BUILD_NUMBER=$BUILD_NUMBER

if  [ $BUILD_NUMBER -eq 1 ]; then
    BUILD_NUMBER_PREFIX=""
else
    BUILD_NUMBER_PREFIX=".post$BUILD_NUMBER"
fi

if [ $PYTHON_VERSION -eq 2 ]; then
    WHEEL_FILENAME_GEN="torch-$BUILD_VERSION$BUILD_NUMBER_PREFIX-cp27-cp27m-macosx_10_6_x86_64.whl"
    WHEEL_FILENAME_NEW="torch-$BUILD_VERSION$BUILD_NUMBER_PREFIX-cp27-none-macosx_10_6_x86_64.whl"
elif [ $PYTHON_VERSION == "3.5" ]; then
    WHEEL_FILENAME_GEN="torch-$BUILD_VERSION$BUILD_NUMBER_PREFIX-cp35-cp35m-macosx_10_6_x86_64.whl"
    WHEEL_FILENAME_NEW="torch-$BUILD_VERSION$BUILD_NUMBER_PREFIX-cp35-cp35m-macosx_10_6_x86_64.whl"
elif [ $PYTHON_VERSION == "3.6" ]; then
    WHEEL_FILENAME_GEN="torch-$BUILD_VERSION$BUILD_NUMBER_PREFIX-cp36-cp36m-macosx_10_7_x86_64.whl"
    WHEEL_FILENAME_NEW="torch-$BUILD_VERSION$BUILD_NUMBER_PREFIX-cp36-cp36m-macosx_10_7_x86_64.whl"
else
    echo "Unhandled python version: $PYTHON_VERSION"
    exit 1
fi

echo "OSX. No CUDA/CUDNN"

###########################################################
export CONDA_ROOT_PREFIX=$(conda info --root)

conda remove --name py2k  --all -y || true
conda remove --name py35k --all -y || true
conda remove --name py36k --all -y || true
conda info --envs

# create env and activate
if [ $PYTHON_VERSION -eq 2 ]
then
    echo "Requested python version 2. Activating conda environment"
    conda create -n py2k python=2 -y
    export CONDA_ENVNAME="py2k"
    source activate py2k
    export PREFIX="$CONDA_ROOT_PREFIX/envs/py2k"
elif [ $PYTHON_VERSION == "3.5" ]; then
    echo "Requested python version 3.5. Activating conda environment"
    conda create -n py35k python=3.5 -y
    export CONDA_ENVNAME="py35k"
    source activate py35k
    export PREFIX="$CONDA_ROOT_PREFIX/envs/py35k"
elif [ $PYTHON_VERSION == "3.6" ]; then
    echo "Requested python version 3.6. Activating conda environment"
    conda create -n py36k python=3.6.0 -y
    export CONDA_ENVNAME="py36k"
    source activate py36k
    export PREFIX="$CONDA_ROOT_PREFIX/envs/py36k"
fi

conda install -n $CONDA_ENVNAME -y numpy==1.11.3 nomkl setuptools pyyaml cffi

# now $PREFIX should point to your conda env
##########################
# now build the binary

echo "Conda root: $CONDA_ROOT_PREFIX"
echo "Env root: $PREFIX"

export PYTORCH_BINARY_BUILD=1
export TH_BINARY_BUILD=1

echo "Python Version:"
python --version

export MACOSX_DEPLOYMENT_TARGET=10.10

rm -rf pytorch-src
git clone --recursive https://github.com/pytorch/pytorch pytorch-src
pushd pytorch-src
git checkout v$BUILD_VERSION

pip install -r requirements.txt || true
python setup.py bdist_wheel

pip uninstall -y torch || true
pip uninstall -y torch || true

pip install dist/$WHEEL_FILENAME_GEN
cd test
./run_test.sh
cd ..

echo "Wheel file: $WHEEL_FILENAME_GEN $WHEEL_FILENAME_NEW"
cp dist/$WHEEL_FILENAME_GEN ../whl/$WHEEL_FILENAME_NEW

popd
