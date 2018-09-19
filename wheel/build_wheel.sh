#!/usr/bin/env bash
set -ex

# Env variables that should be set:
#   DESIRED_PYTHON
#     Which Python version to build for in format 'Maj.min' e.g. '2.7' or '3.6'
#
#   MAC_LIBTORCH_FINAL_FOLDER
#     **absolute** path to folder where final whl packages will be stored. The
#     default should not be used when calling this from a script. The default
#     is 'whl', and corresponds to the default in the wheel/upload.sh script.
#
#   MAC_PACKAGE_WORK_DIR
#     absolute path to a workdir in which to clone an isolated conda
#     installation and pytorch checkout. If the pytorch checkout already exists
#     then it will not be overwritten.

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

# Try to ensure that no other Python installation interferes with this build
if which conda
then
    echo "Please remove Conda from your PATH / DYLD_LIBRARY_PATH completely"
    exit 1
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
if [[ -n "$BUILD_PYTHONLESS" && -z "$MAC_WHEEL_FINAL_FOLDER" ]]; then
    # Don't try to upload the whl if not building it
    MAC_WHEEL_FINAL_FOLDER='whl'
fi
if [[ -z "$MAC_LIBTORCH_FINAL_FOLDER" ]]; then
    MAC_LIBTORCH_FINAL_FOLDER='libtorch'
fi

# Create an isolated directory to store this builds pytorch checkout and conda
# installation
if [[ -z "$MAC_PACKAGE_WORK_DIR" ]]; then
    MAC_PACKAGE_WORK_DIR="$(pwd)/tmp_wheel_conda_${DESIRED_PYTHON}_$(date +%H%M%S)"
fi
mkdir -p "$MAC_PACKAGE_WORK_DIR" || true
pytorch_rootdir="${MAC_PACKAGE_WORK_DIR}/pytorch"
whl_tmp_dir="${MAC_PACKAGE_WORK_DIR}/dist"
mkdir -p "$whl_tmp_dir"

# Python 2.7 and 3.5 build against macOS 10.6, others build against 10.7
if [[ "$desired_python" == 2.7 || "$desired_python" == 3.5 ]]; then
    mac_version='macosx_10_6_x86_64'
else
    mac_version='macosx_10_7_x86_64'
fi

# Determine the wheel package name so that we can rename it later
wheel_filename_gen="${TORCH_PACKAGE_NAME}-${build_version}${build_number_prefix}-cp${python_nodot}-cp${python_nodot}m-${mac_version}.whl"
wheel_filename_new="${TORCH_PACKAGE_NAME}-${build_version}${build_number_prefix}-cp${python_nodot}-none-${mac_version}.whl"

###########################################################
# Install a fresh miniconda with a fresh env

tmp_conda="${MAC_PACKAGE_WORK_DIR}/conda"
tmp_env_name="py$python_nodot"
miniconda_sh="${MAC_PACKAGE_WORK_DIR}/miniconda.sh"
rm -rf "$tmp_conda"
rm -f "$miniconda_sh"
curl https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o "$miniconda_sh"
chmod +x "$miniconda_sh" && \
    "$miniconda_sh" -b -p "$tmp_conda" && \
    rm "$miniconda_sh"
export PATH="$tmp_conda/bin:$PATH"
echo $PATH
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
export MACOSX_DEPLOYMENT_TARGET=10.10

conda install -y cmake numpy==1.11.3 nomkl setuptools pyyaml cffi typing ninja
pip install -r "${pytorch_rootdir}/requirements.txt" || true

pushd "$pytorch_rootdir"
echo "Calling setup.py bdist_wheel at $(date)"
python setup.py bdist_wheel -d "$whl_tmp_dir"
echo "Finished setup.py bdist_wheel at $(date)"
echo "The wheel is in $(find $pytorch_rootdir -name '*.whl')"
popd

# Copy the whl to a final destination before tests are run
echo "Wheel file: $wheel_filename_gen $wheel_filename_new"
if [[ -n "$MAC_WHEEL_FINAL_FOLDER" ]]; then
    mkdir -p "$MAC_WHEEL_FINAL_FOLDER" || true
    cp "$whl_tmp_dir/$wheel_filename_gen" "$MAC_WHEEL_FINAL_FOLDER/$wheel_filename_new"
fi

if [[ -z "$BUILD_PYTHONLESS" ]]; then
    ##########################
    # now test the binary
    pip uninstall -y "$TORCH_PACKAGE_NAME" || true
    pip uninstall -y "$TORCH_PACKAGE_NAME" || true

    # Only one binary is built, so it's safe to just specify the whl directory
    pip install "$TORCH_PACKAGE_NAME" --no-index -f "$whl_tmp_dir" --no-dependencies -v

    # Check that OpenBlas is not linked to
    all_dylibs=($(find "${tmp_conda}/envs/${tmp_env_name}/lib/python${desired_python}/site-packages/torch/" -name '*.dylib'))
    for dylib in "${all_dylibs[@]}"; do
        if [[ -n "$(otool -L $dylib | grep -i openblas)" ]]; then
            echo "BUILD ERROR!!"
            echo "Found openblas as a dependency of $dylib"
            echo "Full dependencies is: $(otool -L $dylib)"
            exit 1
        fi
    done

    # Run the tests
    tests_to_skip=("jit")
    pushd "${pytorch_rootdir}/test"
    echo "Calling python run_test.py -x at $(date)"
    python run_test.py ${RUN_TEST_PARAMS[@]} -v -x "${tests_to_skip[@]}"
    echo "Calling python run_test.py -i at $(date)"
    python run_test.py ${RUN_TEST_PARAMS[@]} -v -i "${tests_to_skip[@]}" || true
    echo "Finished python run_test.py at $(date)"
    popd
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
    cp -r "$(pwd)/any_wheel/torch/lib/include" "$(pwd)/libtorch/"
    cp -r "$(pwd)/any_wheel/torch/share/cmake" "$(pwd)/libtorch/share/"
    rm -rf "$(pwd)/any_wheel"

    # this file is problematic because it can conflict with an API
    # header of the same name
    rm "$(pwd)/libtorch/include/torch/torch.h"

    if [[ -n "$MAC_LIBTORCH_FINAL_FOLDER" ]]; then
        mkdir -p "$MAC_LIBTORCH_FINAL_FOLDER" || true
        zip -rq "$MAC_LIBTORCH_FINAL_FOLDER/libtorch-macos-$PYTORCH_BUILD_VERSION.zip" libtorch
    fi
fi

# Now delete the temporary build folder
# $whl_tmp_dir is not deleted since it will be the only place to find the whl
# if MAC_WHEEL_FINAL_FOLDER isn't specified
rm -rf "$pytorch_rootdir"
rm -rf "$tmp_conda"
