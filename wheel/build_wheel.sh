#!/usr/bin/env bash
set -ex

if [ "$#" -ne 3 ]; then
    echo "illegal number of parameters. Need PY_VERSION BUILD_VERSION BUILD_NUMBER"
    echo "for example: build_wheel.sh 2.7 0.1.6 20"
    echo "Python version should be in format 'M.m'"
    exit 1
fi
if which conda
then
    echo "Please remove Conda from your PATH / DYLD_LIBRARY_PATH completely"
    exit 1
fi

DESIRED_PYTHON=$1
BUILD_VERSION=$2
BUILD_NUMBER=$3

echo "Building for Python: $DESIRED_PYTHON Version: $BUILD_VERSION Build: $BUILD_NUMBER"
echo "This is for OSX. There is no CUDA/CUDNN"
python_nodot="${DESIRED_PYTHON:0:1}${DESIRED_PYTHON:2:1}"

export PYTORCH_BUILD_VERSION=$BUILD_VERSION
export PYTORCH_BUILD_NUMBER=$BUILD_NUMBER

if  [ $BUILD_NUMBER -eq 1 ]; then
    BUILD_NUMBER_PREFIX=""
else
    BUILD_NUMBER_PREFIX=".post$BUILD_NUMBER"
fi

# Fill in empty parameters with defaults
if [[ -z "$TORCH_PACKAGE_NAME" ]]; then
    TORCH_PACKAGE_NAME='torch'
fi
if [[ -z "$GITHUB_ORG" ]]; then
    GITHUB_ORG='pytorch'
fi
if [[ -z "$PYTORCH_BRANCH" ]]; then
    PYTORCH_BRANCH="v${BUILD_VERSION}"
fi
if [[ -z "$RUN_TEST_PARAMS" ]]; then
    RUN_TEST_PARAMS=()
fi
if [[ -z "PYTORCH_WHEEL_DESTDIR" ]]; then
    current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
    PYTORCH_WHEEL_DESTDIR="${current_dir}/../whl"
fi

# Python 2.7 and 3.5 build against macOS 10.6, others build against 10.7
if [[ "$DESIRED_PYTHON" == 2.7 || "$DESIRED_PYTHON" == 3.5 ]]; then
    mac_version='macosx_10_6_x86_64'
else
    mac_version='macosx_10_7_x86_64'
fi
wheel_filename_gen="${TORCH_PACKAGE_NAME}-${BUILD_VERSION}${BUILD_NUMBER_PREFIX}-cp${python_nodot}-cp${python_nodot}m-${mac_version}.whl"
wheel_filename_new="${TORCH_PACKAGE_NAME}-${BUILD_VERSION}${BUILD_NUMBER_PREFIX}-cp${python_nodot}-none-${mac_version}.whl"

###########################################################
# Install a fresh miniconda with a fresh env

rm -rf tmp_conda
rm -f Miniconda3-latest-MacOSX-x86_64.sh
curl https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o miniconda.sh
chmod +x miniconda.sh && \
    ./miniconda.sh -b -p tmp_conda && \
    rm miniconda.sh
condapath=$(python -c "import os; print(os.path.realpath('tmp_conda'))")
export PATH="$condapath/bin:$PATH"
echo $PATH


export CONDA_ROOT_PREFIX=$(conda info --root)

conda install -y cmake

conda remove --name py2k  --all -y || true
conda remove --name py35k --all -y || true
conda remove --name py36k --all -y || true
conda remove --name py37k --all -y || true
conda info --envs

# create env and activate
echo "Requested python version ${DESIRED_PYTHON}. Activating conda environment"
export CONDA_ENVNAME="py${python_nodot}k"
conda env remove -yn "$CONDA_ENVNAME" || true
conda create -n "$CONDA_ENVNAME" python="$DESIRED_PYTHON" -y
source activate "$CONDA_ENVNAME"
export PREFIX="$CONDA_ROOT_PREFIX/envs/$CONDA_ENVNAME"

conda install -n $CONDA_ENVNAME -y numpy==1.11.3 nomkl setuptools pyyaml cffi typing ninja

# now $PREFIX should point to your conda env
##########################
# now build the binary

echo "Conda root: $CONDA_ROOT_PREFIX"
echo "Env root: $PREFIX"

export TH_BINARY_BUILD=1

echo "Python Version:"
python --version

export MACOSX_DEPLOYMENT_TARGET=10.10

rm -rf pytorch-src
git clone "https://github.com/${GITHUB_ORG}/pytorch" pytorch-src
pushd pytorch-src
if ! git checkout "$PYTORCH_BRANCH" ; then
    echo "Could not checkout $PYTORCH_BRANCH, so trying tags/v${BUILD_VERSION}"
    git checkout tags/v${BUILD_VERSION}
fi
git submodule update --init --recursive

pip install -r requirements.txt || true
python setup.py bdist_wheel

##########################
# now test the binary
pip uninstall -y torch || true
pip uninstall -y torch || true

pip install dist/$wheel_filename_gen
pushd test
python run_test.py ${RUN_TEST_PARAMS[@]} || true
popd

echo "Wheel file: $wheel_filename_gen $wheel_filename_new"
cp dist/$wheel_filename_gen "${PYTORCH_WHEEL_DESTDIR}/$}wheel_filename_new}"

popd
