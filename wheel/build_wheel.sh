#!/usr/bin/env bash
set -e

if [ "$#" -ne 4 ]; then
    echo "illegal number of parameters. Need PY_VERSION CUDA_VERSION BUILD_VERSION BUILD_NUMBER"
    echo "for example: build_wheel.sh 2 7.5 0.1.6 20"
    exit 1
fi

PYTHON_VERSION=$1
CUDA_VERSION=$2
BUILD_VERSION=$3
BUILD_NUMBER=$4

echo "Building for Python: $PYTHON_VERSION CUDA: $CUDA_VERSION Version: $BUILD_VERSION Build: $BUILD_NUMBER"

export PYTORCH_BUILD_VERSION=$BUILD_VERSION
export PYTORCH_BUILD_NUMBER=$BUILD_NUMBER

if [[ $CUDA_VERSION == "7.5" ]]; then

    CUDNN_VERSION="5.1.3"
    MAGMA_PACKAGE="magma-cuda75"

    if [ $PYTHON_VERSION -eq 2 ]; then
        WHEEL_FILENAME="torch-$BUILD_VERSION.post$BUILD_NUMBER-cp27-cp27mu-linux_x86_64.whl"
    elif [ $PYTHON_VERSION -eq 3 ]; then
        WHEEL_FILENAME="torch-$BUILD_VERSION.post$BUILD_NUMBER-cp35-cp35m-linux_x86_64.whl"
    else
        echo "Unhandled python version: $PYTHON_VERSION"
        exit 1
    fi
elif [[ $CUDA_VERSION == "8.0" ]]; then

    CUDNN_VERSION="5.1.5"
    MAGMA_PACKAGE="magma-cuda80"

    if [ $PYTHON_VERSION -eq 2 ]; then
        WHEEL_FILENAME="torch-$BUILD_VERSION.post$BUILD_NUMBER-cp27-cp27mu-linux_x86_64.whl"
    elif [ $PYTHON_VERSION -eq 3 ]; then
        WHEEL_FILENAME="torch-$BUILD_VERSION.post$BUILD_NUMBER-cp35-cp35m-linux_x86_64.whl"
    else
        echo "Unhandled python version: $PYTHON_VERSION"
        exit 1
    fi
elif [[ $CUDA_VERSION == "-1" ]]; then # OSX build
    if [ $PYTHON_VERSION -eq 2 ]; then
        WHEEL_FILENAME="torch-$BUILD_VERSION.post$BUILD_NUMBER-cp27-cp27m-macosx_10_7_x86_64.whl"
    elif [ $PYTHON_VERSION -eq 3 ]; then
        WHEEL_FILENAME="torch-$BUILD_VERSION.post$BUILD_NUMBER-cp35-cp35m-macosx_10_6_x86_64.whl"
    else
        echo "Unhandled python version: $PYTHON_VERSION"
        exit 1
    fi    
else
    echo "Unhandled CUDA version $CUDA_VERSION"
    exit 1
fi

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

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    conda install -n $CONDA_ENVNAME -y numpy setuptools pyyaml mkl cffi gcc
    conda install -n $CONDA_ENVNAME -y $MAGMA_PACKAGE -c soumith
else
    conda install -n $CONDA_ENVNAME -y numpy setuptools pyyaml cffi
fi

# now $PREFIX should point to your conda env
##########################
# now build the binary

echo "Conda root: $CONDA_ROOT_PREFIX"
echo "Env root: $PREFIX"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
    export CMAKE_PREFIX_PATH=$PREFIX
fi

# compile for Kepler, Kepler+Tesla, Maxwell
# 3.0, 3.5, 3.7, 5.0, 5.2+PTX
export TORCH_CUDA_ARCH_LIST="3.0;3.5;5.0;5.2+PTX"
if [[ $CUDA_VERSION == "8.0" ]]; then
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1"
fi
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export PYTORCH_BINARY_BUILD=1
export TH_BINARY_BUILD=1

# OSX has no cuda or mkl
if [[ "$OSTYPE" == "linux-gnu"* ]]; then 
    export PYTORCH_SO_DEPS="\
/usr/local/cuda/lib64/libcusparse.so.$CUDA_VERSION \
/usr/local/cuda/lib64/libcublas.so.$CUDA_VERSION \
/usr/local/cuda/lib64/libcudart.so.$CUDA_VERSION \
/usr/local/cuda/lib64/libcudart.so \
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
fi

echo "Python Version:"
python --version

export MACOSX_DEPLOYMENT_TARGET=10.10

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

echo "Wheel file: $WHEEL_FILENAME"
if [[ $CUDA_VERSION == "7.5" ]]; then
    cp dist/$WHEEL_FILENAME ../whl/cu75/
elif [[ $CUDA_VERSION == "8.0" ]]; then
    cp dist/$WHEEL_FILENAME ../whl/cu80/
elif [[ $CUDA_VERSION == "-1" ]]; then # OSX build
    cp dist/$WHEEL_FILENAME ../whl/
fi

popd
