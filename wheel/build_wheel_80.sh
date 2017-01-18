#!/usr/bin/env bash
set -e

BUILD_VERSION="0.1.6"
BUILD_NUMBER=17

export PYTORCH_BUILD_VERSION=$BUILD_VERSION
export PYTORCH_BUILD_NUMBER=$BUILD_NUMBER

# PYTHON_VERSION=2

# CUDA_VERSION="8.0"
# CUDNN_VERSION="5.1.5"
# MAGMA_PACKAGE="magma-cuda80"

# WHEEL_FILENAME="torch-$BUILD_VERSION.post$BUILD_NUMBER-cp27-cp27mu-linux_x86_64.whl"
# WHEEL_NEWFILENAME="torch_cuda80-$BUILD_VERSION.post$BUILD_NUMBER-cp27-cp27mu-linux_x86_64.whl"


PYTHON_VERSION=3

CUDA_VERSION="8.0"
CUDNN_VERSION="5.1.5"
MAGMA_PACKAGE="magma-cuda80"

WHEEL_FILENAME="torch-$BUILD_VERSION.post$BUILD_NUMBER-cp35-cp35m-linux_x86_64.whl"
WHEEL_NEWFILENAME="torch_cuda80-$BUILD_VERSION.post$BUILD_NUMBER-cp35-cp35m-linux_x86_64.whl"

###########################################################
export CONDA_ROOT_PREFIX=$(conda info --root)

# create env and activate
if [ $PYTHON_VERSION -eq 2 ]
then
    echo "Requested python version 2. Activating conda environment"
    if ! conda info --envs | grep py2k
    then
        # create virtual env and activate it
        conda create -n py2k python=2 -y
    fi
    export CONDA_ENVNAME="py2k"
    source activate py2k
    export PREFIX="$CONDA_ROOT_PREFIX/envs/py2k"
else
    echo "Requested python version 3. Activating conda environment"
    if ! conda info --envs | grep py3k
    then
        # create virtual env and activate it
        conda create -n py3k python=3.5 -y
    fi
    export CONDA_ENVNAME="py3k"
    source activate py3k
    export PREFIX="$CONDA_ROOT_PREFIX/envs/py3k"
fi
conda install -n $CONDA_ENVNAME -y numpy setuptools pyyaml mkl cffi gcc
conda install -n $CONDA_ENVNAME -y $MAGMA_PACKAGE -c https://conda.anaconda.org/t/6N-MsQ4WZ7jo/soumith

# now $PREFIX should point to your conda env
##########################
# now build the binary

echo "Conda root: $CONDA_ROOT_PREFIX"
echo "Env root: $PREFIX"

export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX

# compile for Kepler, Kepler+Tesla, Maxwell, Pascal
# 3.0, 3.5, 3.7, 5.0, 5.2, 6.1+PTX
export TORCH_CUDA_ARCH_LIST="3.0;3.5;5.2;6.1+PTX"
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export PYTORCH_BINARY_BUILD=1
export TH_BINARY_BUILD=1
export PYTORCH_SO_DEPS="\
/usr/local/cuda/lib64/libcusparse.so.$CUDA_VERSION \
/usr/local/cuda/lib64/libcublas.so.$CUDA_VERSION \
/usr/local/cuda/lib64/libcudart.so.$CUDA_VERSION \
/usr/local/cuda/lib64/libcurand.so.$CUDA_VERSION \
/usr/local/cuda/lib64/libcudnn.so.$CUDNN_VERSION \
/usr/local/cuda/lib64/libcudnn.so.5 \
$PREFIX/lib/libmkl_intel_lp64.so \
$PREFIX/lib/libmkl_sequential.so \
$PREFIX/lib/libmkl_core.so \
$PREFIX/lib/libmkl_avx2.so \
$PREFIX/lib/libmkl_def.so \
$PREFIX/lib/libmkl_intel_thread.so \
$PREFIX/lib/libgomp.so.1 \
"

echo "Python Version:"
python --version


rm -rf pytorch-src
git clone https://github.com/pytorch/pytorch pytorch-src
pushd pytorch-src
git checkout v$BUILD_VERSION

pip install -r requirements.txt || true
python setup.py bdist_wheel

pip uninstall -y torch || true
pip uninstall -y torch || true

pip install dist/$WHEEL_FILENAME
cd test
./run_test.sh
cd ..

echo aws s3 cp dist/$WHEEL_FILENAME s3://pytorch/whl/$WHEEL_NEWFILENAME --acl public-read
popd
