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

desired_python=$1
build_version=$2
build_number=$3

echo "Building for Python: $desired_python Version: $build_version Build: $build_number"
echo "This is for OSX. There is no CUDA/CUDNN"
python_nodot="${desired_python:0:1}${desired_python:2:1}"

# Version: setup.py uses $PYTORCH_BUILD_VERSION.post$PYTORCH_BUILD_NUMBER if
# PYTORCH_BUILD_NUMBER > 1
if [[ -n "$OVERRIDE_PACKAGE_VERSION" ]]; then
    # This will be the *exact* version, since build_number<1
    build_version="$OVERRIDE_PACKAGE_VERSION"
    build_number=0
    build_number_prefix=''
else
    if [[ "$build_version" == 'nightly' ]]; then
        # So, pip actually "normalizes" versions from 2018.08.09 to 2018.8.9,
        # so to to get the right name of the final wheel we have to normalize
        # the version too. Also couldn't get \d working on MacOS's default sed.
        build_version=$(echo $(date +%Y.%m.%d) | sed -E 's/([0-9][0-9][0-9][0-9].)0?([0-9][0-9]?.)0?([0-9][0-9]?)/\1\2\3/g' )
    fi
    if [[ $build_number -eq 1 ]]; then
        build_number_prefix=""
    else
        build_number_prefix=".post$build_number"
    fi
fi
export PYTORCH_BUILD_VERSION=$build_version
export PYTORCH_BUILD_NUMBER=$build_number

# Fill in empty parameters with defaults
if [[ -z "$TORCH_PACKAGE_NAME" ]]; then
    TORCH_PACKAGE_NAME='torch'
fi
if [[ -z "$GITHUB_ORG" ]]; then
    GITHUB_ORG='pytorch'
fi
if [[ -z "$PYTORCH_BRANCH" ]]; then
    PYTORCH_BRANCH="v${build_version}"
fi
if [[ -z "$RUN_TEST_PARAMS" ]]; then
    RUN_TEST_PARAMS=()
fi

# Python 2.7 and 3.5 build against macOS 10.6, others build against 10.7
if [[ "$desired_python" == 2.7 || "$desired_python" == 3.5 ]]; then
    mac_version='macosx_10_6_x86_64'
else
    mac_version='macosx_10_7_x86_64'
fi
wheel_filename_gen="${TORCH_PACKAGE_NAME}-${build_version}${build_number_prefix}-cp${python_nodot}-cp${python_nodot}m-${mac_version}.whl"
wheel_filename_new="${TORCH_PACKAGE_NAME}-${build_version}${build_number_prefix}-cp${python_nodot}-none-${mac_version}.whl"

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
echo "Requested python version ${desired_python}. Activating conda environment"
export CONDA_ENVNAME="py${python_nodot}k"
conda env remove -yn "$CONDA_ENVNAME" || true
conda create -n "$CONDA_ENVNAME" python="$desired_python" -y
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
    echo "Could not checkout $PYTORCH_BRANCH, so trying tags/v${build_version}"
    git checkout tags/v${build_version}
fi
git submodule update --init --recursive

pip install -r requirements.txt || true

python setup.py bdist_wheel

if [[ -z "$BUILD_PYTHONLESS" ]];
then
    ##########################
    # now test the binary
    pip uninstall -y torch || true
    pip uninstall -y torch || true

    pip install dist/$wheel_filename_gen
    pushd test
    python run_test.py ${RUN_TEST_PARAMS[@]} || true
    popd

    # N.B. this is hardcoded to match wheel/upload.sh, which uploads from whl/
    echo "Wheel file: $wheel_filename_gen $wheel_filename_new"
    mkdir -p whl
    cp dist/$wheel_filename_gen "whl/$wheel_filename_new"
else
    mkdir -p build
    pushd build
    python ../tools/build_libtorch.py
    popd

    mkdir -p libtorch/{lib,bin,include,share}
    cp -r build/lib libtorch/
    cp -r cmake libtorch/share/

    # for now, the headers for the libtorch package will just be
    # copied in from the wheel
    unzip -d any_wheel dist/$wheel_filename_gen
    cp -r any_wheel/torch/lib/include libtorch/
    rm -rf any_wheel

    # this file is problematic because it can conflict with an API
    # header of the same name
    rm libtorch/include/torch/torch.h

    mkdir -p ../wheel/libtorch_packages
    zip -rq ../wheel/libtorch_packages/libtorch-macos.zip libtorch
fi

popd
