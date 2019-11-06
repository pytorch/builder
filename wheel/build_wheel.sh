#!/usr/bin/env bash
set -ex
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Env variables that should be set:
#   DESIRED_PYTHON
#     Which Python version to build for in format 'Maj.min' e.g. '2.7' or '3.6'
#
#   PYTORCH_FINAL_PACKAGE_DIR
#     **absolute** path to folder where final whl packages will be stored. The
#     default should not be used when calling this from a script. The default
#     is 'whl', and corresponds to the default in the wheel/upload.sh script.
#
#   MAC_PACKAGE_WORK_DIR
#     absolute path to a workdir in which to clone an isolated conda
#     installation and pytorch checkout. If the pytorch checkout already exists
#     then it will not be overwritten.

# Function to retry functions that sometimes timeout or have flaky failures
retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

# Parameters
if [[ -n "$DESIRED_PYTHON" && -n "$PYTORCH_BUILD_VERSION" && -n "$PYTORCH_BUILD_NUMBER" ]]; then
    desired_python="$DESIRED_PYTHON"
    build_version="$PYTORCH_BUILD_VERSION"
    build_number="$PYTORCH_BUILD_NUMBER"
else
    if [ "$#" -ne 3 ]; then
        echo "illegal number of parameters. Need PY_VERSION BUILD_VERSION BUILD_NUMBER"
        echo "for example: build_wheel.sh 2.7 0.1.6 20"
        echo "Python version should be in format 'M.m'"
        exit 1
    fi
    desired_python=$1
    build_version=$2
    build_number=$3
fi

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
TORCH_PACKAGE_NAME="$(echo $TORCH_PACKAGE_NAME | tr '-' '_')"
if [[ -z "$PYTORCH_REPO" ]]; then
    PYTORCH_REPO='pytorch'
fi
if [[ -z "$PYTORCH_BRANCH" ]]; then
    PYTORCH_BRANCH="v${build_version}"
fi
if [[ -z "$RUN_TEST_PARAMS" ]]; then
    RUN_TEST_PARAMS=()
fi
if [[ -z "$PYTORCH_FINAL_PACKAGE_DIR" ]]; then
    if [[ -n "$BUILD_PYTHONLESS" ]]; then
        PYTORCH_FINAL_PACKAGE_DIR='libtorch'
    else
        PYTORCH_FINAL_PACKAGE_DIR='whl'
    fi
fi
mkdir -p "$PYTORCH_FINAL_PACKAGE_DIR" || true

# Create an isolated directory to store this builds pytorch checkout and conda
# installation
if [[ -z "$MAC_PACKAGE_WORK_DIR" ]]; then
    MAC_PACKAGE_WORK_DIR="$(pwd)/tmp_wheel_conda_${DESIRED_PYTHON}_$(date +%H%M%S)"
fi
mkdir -p "$MAC_PACKAGE_WORK_DIR" || true
pytorch_rootdir="${MAC_PACKAGE_WORK_DIR}/pytorch"
whl_tmp_dir="${MAC_PACKAGE_WORK_DIR}/dist"
mkdir -p "$whl_tmp_dir"

# Python 3.5 build against macOS 10.6, others build against 10.7
# NB: Sometimes Anaconda revs the version, in which case you'll have to
# update this!
# An example of this happened on Aug 13, 2019, when osx-64/python-2.7.16-h97142e2_2.tar.bz2
# was uploaded to https://anaconda.org/anaconda/python/files
if [[ "$desired_python" == 3.7 ]]; then
    mac_version='macosx_10_7_x86_64'
elif [[ "$desired_python" == 3.5 ]]; then
    mac_version='macosx_10_6_x86_64'
else
    mac_version='macosx_10_7_x86_64'
fi

# Determine the wheel package name so that we can rename it later
wheel_filename_gen="${TORCH_PACKAGE_NAME}-${build_version}${build_number_prefix}-cp${python_nodot}-cp${python_nodot}m-${mac_version}.whl"
wheel_filename_new="${TORCH_PACKAGE_NAME}-${build_version}${build_number_prefix}-cp${python_nodot}-none-${mac_version}.whl"

###########################################################
# Install into a fresh env
tmp_env_name="wheel_py$python_nodot"
conda create -yn "$tmp_env_name" python="$desired_python"
source activate "$tmp_env_name"

# Have a separate Pytorch repo clone
if [[ ! -d "$pytorch_rootdir" ]]; then
    git clone "https://github.com/${PYTORCH_REPO}/pytorch" "$pytorch_rootdir"
    pushd "$pytorch_rootdir"
    if ! git checkout "$PYTORCH_BRANCH" ; then
        echo "Could not checkout $PYTORCH_BRANCH, so trying tags/v${build_version}"
        git checkout tags/v${build_version}
    fi
    popd
fi
pushd "$pytorch_rootdir"
git submodule update --init --recursive
popd

##########################
# now build the binary


export TH_BINARY_BUILD=1
export INSTALL_TEST=0 # dont install test binaries into site-packages
export MACOSX_DEPLOYMENT_TARGET=10.10
export CMAKE_PREFIX_PATH=${CONDA_PREFIX:-"$(dirname $(which conda))/../"}

retry conda install -yq cmake numpy==1.11.3 nomkl setuptools pyyaml cffi typing ninja requests
retry conda install -yq mkl-include==2019.5 mkl-static==2019.5 -c intel
retry pip install -qr "${pytorch_rootdir}/requirements.txt" || true

# For USE_DISTRIBUTED=1 on macOS, need libuv and pkg-config to find libuv.
export USE_DISTRIBUTED=1
retry conda install -yq libuv pkg-config

pushd "$pytorch_rootdir"
echo "Calling setup.py bdist_wheel at $(date)"

python setup.py bdist_wheel -d "$whl_tmp_dir"

echo "Finished setup.py bdist_wheel at $(date)"

echo "delocating wheel dependencies"
retry pip install https://github.com/matthew-brett/delocate/archive/master.zip
echo "found the following wheels:"
find $whl_tmp_dir -name "*.whl"
echo "running delocate"
find $whl_tmp_dir -name "*.whl" | xargs -I {} delocate-wheel {}
find $whl_tmp_dir -name "*.whl" | xargs -I {} delocate-listdeps {}
echo "Finished delocating wheels at $(date)"

echo "The wheel is in $(find $pytorch_rootdir -name '*.whl')"
popd

if [[ -z "$BUILD_PYTHONLESS" ]]; then
    # Copy the whl to a final destination before tests are run
    echo "Wheel file: $wheel_filename_gen $wheel_filename_new"
    cp "$whl_tmp_dir/$wheel_filename_gen" "$PYTORCH_FINAL_PACKAGE_DIR/$wheel_filename_new"

    ##########################
    # now test the binary
    pip uninstall -y "$TORCH_PACKAGE_NAME" || true
    pip uninstall -y "$TORCH_PACKAGE_NAME" || true

    # Only one binary is built, so it's safe to just specify the whl directory
    pip install "$TORCH_PACKAGE_NAME" --no-index -f "$whl_tmp_dir" --no-dependencies -v

    # Run the tests
    echo "$(date) :: Running tests"
    pushd "$pytorch_rootdir"
    "${SOURCE_DIR}/../run_tests.sh" 'wheel' "$desired_python" 'cpu'
    popd
    echo "$(date) :: Finished tests"
else
    pushd "$pytorch_rootdir"
    mkdir -p build
    pushd build
    python ../tools/build_libtorch.py
    popd

    mkdir -p libtorch/{lib,bin,include,share}
    cp -r "$(pwd)/build/lib" "$(pwd)/libtorch/"

    # for now, the headers for the libtorch package will just be
    # copied in from the wheel
    unzip -d any_wheel "$whl_tmp_dir/$wheel_filename_gen"
    if [[ -d $(pwd)/any_wheel/torch/include ]]; then
        cp -r "$(pwd)/any_wheel/torch/include" "$(pwd)/libtorch/"
    else
        cp -r "$(pwd)/any_wheel/torch/lib/include" "$(pwd)/libtorch/"
    fi
    cp -r "$(pwd)/any_wheel/torch/share/cmake" "$(pwd)/libtorch/share/"
    cp -r "$(pwd)/any_wheel/torch/.dylibs/libiomp5.dylib" "$(pwd)/libtorch/lib/"
    rm -rf "$(pwd)/any_wheel"

    echo $PYTORCH_BUILD_VERSION > libtorch/build-version
    echo "$(pushd $pytorch_rootdir && git rev-parse HEAD)" > libtorch/build-hash

    zip -rq "$PYTORCH_FINAL_PACKAGE_DIR/libtorch-macos-$PYTORCH_BUILD_VERSION.zip" libtorch
    cp "$PYTORCH_FINAL_PACKAGE_DIR/libtorch-macos-$PYTORCH_BUILD_VERSION.zip"  \
       "$PYTORCH_FINAL_PACKAGE_DIR/libtorch-macos-latest.zip"
fi

# Now delete the temporary build folder and temporary env
# $whl_tmp_dir is not deleted since it will be the only place to find the whl
# if PYTORCH_FINAL_PACKAGE_DIR isn't specified
source deactivate
conda env remove -yn "$tmp_env_name"
