#!/bin/bash
set -eux -o pipefail

# Essentially runs pytorch/test/run_test.py, but keeps track of which tests to
# skip in a centralized place.
#
# TODO Except for a few tests, this entire file is a giant TODO. Why are these
# tests # failing?
# TODO deal with Windows

# This script expects to be in the pytorch root folder
if [[ ! -d 'test' || ! -f 'test/run_test.py' ]]; then
    echo "builder/test.sh expects to be run from the Pytorch root directory " \
         "but I'm actually in $(pwd)"
    exit 2
fi

# Allow master skip of all tests
if [[ -n "${SKIP_ALL_TESTS:-}" ]]; then
    exit 0
fi

# If given specific test params then just run those
if [[ -n "${RUN_TEST_PARAMS:-}" ]]; then
    echo "$(date) :: Calling user-command $(pwd)/test/run_test.py ${RUN_TEST_PARAMS[@]}"
    python test/run_test.py ${RUN_TEST_PARAMS[@]}
    exit 0
fi

# Function to retry functions that sometimes timeout or have flaky failures
retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

# Parameters
##############################################################################
if [[ "$#" != 3 ]]; then
  if [[ -z "${DESIRED_PYTHON:-}" || -z "${PACKAGE_TYPE:-}" || -z "${GPU_ARCH_TYPE}" ]]; then
    echo "USAGE: run_tests.sh  PACKAGE_TYPE  DESIRED_PYTHON  GPU_ARCH_TYPE"
    echo "The env variable PACKAGE_TYPE must be set to 'conda' or 'manywheel' or 'libtorch'"
    echo "The env variable DESIRED_PYTHON must be set like '2.7mu' or '3.6m' etc"
    echo "The env variable GPU_ARCH_TYPE must be set like 'cpu' or 'cuda' or 'rocm' etc"
    exit 1
  fi
  package_type="$PACKAGE_TYPE"
  py_ver="$DESIRED_PYTHON"
else
  package_type="$1"
  py_ver="$2"
fi

NUMPY_PACKAGE=""
if [[ ${py_ver} == "3.10" ]]; then
    PROTOBUF_PACKAGE="protobuf>=3.17.2"
    NUMPY_PACKAGE="numpy>=1.21.2"
else
    PROTOBUF_PACKAGE="protobuf=3.14.0"
fi

# Environment initialization
if [[ "$package_type" == conda || "$(uname)" == Darwin ]]; then
    # Why are there two different ways to install dependencies after installing an offline package?
    # The "cpu" conda package for pytorch doesn't actually depend on "cpuonly" which means that
    # when we attempt to update dependencies using "conda update --all" it will attempt to install
    # whatever "cudatoolkit" your current computer relies on (which is sometimes none). When conda
    # tries to install this cudatoolkit that correlates with your current hardware it will also
    # overwrite the currently installed "local" pytorch package meaning you aren't actually testing
    # the right package.
    # TODO (maybe): Make the "cpu" package of pytorch depend on "cpuonly"
    if [[ "${GPU_ARCH_TYPE}" = 'cpu' ]]; then
      # Installing cpuonly will also install dependencies as well
      retry conda install -y -c pytorch cpuonly
    else
      # Install dependencies from installing the pytorch conda package offline
      retry conda update -yq --all -c defaults -c pytorch -c numba/label/dev
    fi
    # Install the testing dependencies
    retry conda install -yq future hypothesis ${NUMPY_PACKAGE} ${PROTOBUF_PACKAGE} pytest setuptools six typing_extensions pyyaml
else
    retry pip install -qr requirements.txt || true
    retry pip install -q hypothesis protobuf pytest setuptools || true
    numpy_ver=1.15
    case "$(python --version 2>&1)" in
      *2* | *3.5* | *3.6*)
        numpy_ver=1.11
        ;;
    esac
    retry pip install -q "numpy==${numpy_ver}" || true
fi

echo "Testing with:"
pip freeze
conda list || true

##############################################################################
# Smoke tests
##############################################################################
# TODO use check_binary.sh, which requires making sure it runs on Windows
pushd /
echo "Smoke testing imports"
python -c 'import torch'

# Test that MKL is there
if [[ "$(uname)" == 'Darwin' && "$package_type" == *wheel ]]; then
    echo 'Not checking for MKL on Darwin wheel packages'
else
    echo "Checking that MKL is available"
    python -c 'import torch; exit(0 if torch.backends.mkl.is_available() else 1)'
fi

if [[ "$OSTYPE" == "msys" ]]; then
    GPUS=$(wmic path win32_VideoController get name)
    if [[ ! "$GPUS" == *NVIDIA* ]]; then
        echo "Skip CUDA tests for machines without a Nvidia GPU card"
        exit 0
    fi
fi

# Test that the version number is consistent during building and testing
if [[ "$PYTORCH_BUILD_NUMBER" -gt 1 ]]; then
    expected_version="${PYTORCH_BUILD_VERSION}.post${PYTORCH_BUILD_NUMBER}"
else
    expected_version="${PYTORCH_BUILD_VERSION}"
fi
echo "Checking that we are testing the package that is just built"
python -c "import torch; exit(0 if torch.__version__ == '$expected_version' else 1)"

# Test that CUDA builds are setup correctly
if [[ "${GPU_ARCH_TYPE}" != 'cpu' ]]; then
    # Test CUDA archs
    echo "Checking that CUDA archs are setup correctly"
    timeout 20 python -c 'import torch; torch.randn([3,5]).cuda()'

    # These have to run after CUDA is initialized
    echo "Checking that magma is available"
    python -c 'import torch; torch.rand(1).cuda(); exit(0 if torch.cuda.has_magma else 1)'
    echo "Checking that CuDNN is available"
    python -c 'import torch; exit(0 if torch.backends.cudnn.is_available() else 1)'
fi

# Check that OpenBlas is not linked to on Macs
if [[ "$(uname)" == 'Darwin' ]]; then
    echo "Checking the OpenBLAS is not linked to"
    all_dylibs=($(find "$(python -c "import site; print(site.getsitepackages()[0])")"/torch -name '*.dylib'))
    for dylib in "${all_dylibs[@]}"; do
        if [[ -n "$(otool -L $dylib | grep -i openblas)" ]]; then
            echo "Found openblas as a dependency of $dylib"
            echo "Full dependencies is: $(otool -L $dylib)"
            exit 1
        fi
    done
fi

popd
