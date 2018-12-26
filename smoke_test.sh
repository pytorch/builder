set -ex

# This is meant to be run in either a docker image or in a Mac. This assumes an
# environment that will be teared down after execution is finishes, so it will
# probably mess up what environment it runs in

# Use today's date if none is given
if [[ "$DATE" == 'today' ]]; then
    DATE="$(date +%Y%m%d)"
fi

# Helper variables for logging
date_under="${DATE:1:4}_${DATE:4:2}_${DATE:6:2}"
if [[ "$(uname)" == 'Darwin' ]]; then
  macos_or_linux='macos'
else
  macos_or_linux='linux'
fi
log_url="https://download.pytorch.org/nightly_logs/$macos_or_linux/$date_under/${PACKAGE_TYPE}_${DESIRED_PYTHON}_${DESIRED_CUDA}.log"

# DESIRED_PYTHON is in format 2.7m?u?
# DESIRED_CUDA is in format cu80 (or 'cpu')

# Generate M.m formats for CUDA and Python versions
if [[ "$DESIRED_CUDA" != cpu ]]; then
  cuda_dot="$(echo $DESIRED_CUDA | tr -d 'cpu')"
  if [[ "${#cuda_dot}" == 2 ]]; then
    cuda_dot="${cuda_dot:0:1}.${cuda_dot:1}"
  else
    cuda_dot="${cuda_dot:0:2}.${cuda_dot:2}"
  fi
fi
py_dot="${DESIRED_PYTHON:0:3}"

# Generate "long" python versions cp27-cp27mu
py_long="cp${DESIRED_PYTHON:0:1}${DESIRED_PYTHON:2:1}-cp${DESIRED_PYTHON:0:1}${DESIRED_PYTHON:2}"

# Determine package name
if [[ "$PACKAGE_TYPE" == *wheel ]]; then
  package_name='torch-nightly'
elif [[ "$DESIRED_CUDA" == 'cpu' && "$(uname)" != 'Darwin' ]]; then
  package_name='pytorch-nightly-cpu'
else
  package_name='pytorch-nightly'
fi
package_name_and_version="${package_name}==${NIGHTLIES_DATE_PREAMBLE}${DATE}"

# Switch to the desired python
if [[ "$PACKAGE_TYPE" == 'conda' || "$(uname)" == 'Darwin' ]]; then
  # Install Anaconda if we're on Mac
  if [[ "$(uname)" == 'Darwin' ]]; then
    pyroot="${TMPDIR}/anaconda"
    rm -rf "$pyroot"
    curl -o ${TMPDIR}/anaconda.sh https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
    /bin/bash ${TMPDIR}/anaconda.sh -b -p ${TMPDIR}/anaconda
    rm -f ${TMPDIR}/anaconda.sh
    export PATH="$pyroot/bin:${PATH}"
    source $pyroot/bin/activate
  else
    pyroot="/opt/conda"
  fi

  # Create a conda env
  conda create -yn test python="$DESIRED_PYTHON" && source activate test
  conda install -yq future numpy protobuf six
else
  export PATH=/opt/python/${py_long}/bin:$PATH
  pip install future numpy protobuf six
fi

# Switch to the desired CUDA if using the conda-cuda Docker image
if [[ "$PACKAGE_TYPE" == 'conda' ]]; then
  rm -rf /usr/local/cuda || true
  if [[ "$DESIRED_CUDA" != 'cpu' ]]; then
    ln -s "/usr/local/cuda-${cuda_dot}" /usr/local/cuda
    export CUDA_VERSION=$(ls /usr/local/cuda/lib64/libcudart.so.*|sort|tac | head -1 | rev | cut -d"." -f -3 | rev)
    export CUDNN_VERSION=$(ls /usr/local/cuda/lib64/libcudnn.so.*|sort|tac | head -1 | rev | cut -d"." -f -3 | rev)
  fi
fi

# Print some debugging info
python --version
pip --version
which python
if [[ "$PACKAGE_TYPE" == 'conda' ]]; then
  conda search -c pytorch "$package_name"
else
  if [[ "$PACKAGE_TYPE" == 'libtorch' ]]; then
    s3_dir='libtorch'
  else
    s3_dir='whl'
  fi
  curl "https://download.pytorch.org/$s3_dir/nightly/$DESIRED_CUDA/torch_nightly.html" -v
fi

# Install the package for the requested date
if [[ "$PACKAGE_TYPE" == 'conda' ]]; then
  if [[ "$DESIRED_CUDA" == 'cpu' || "$DESIRED_CUDA" == 'cu90' ]]; then
    conda install -yq -c pytorch "$package_name_and_version"
  else
    conda install -yq -c pytorch "cuda${DESIRED_CUDA:2}" "$package_name_and_version"
  fi
else
  pip install "$package_name_and_version" \
      -f "https://download.pytorch.org/$s3_dir/nightly/$DESIRED_CUDA/torch_nightly.html" \
      --no-cache-dir \
      --no-index \
      -v
fi

# Check that conda didn't do something dumb
if [[ "$PACKAGE_TYPE" == 'conda' ]]; then
  # Check that conda didn't change the Python version out from under us
  if [[ -z "$(python --version 2>&1 | grep -o $py_dot)" ]]; then
    echo "The Python version has changed to $(python --version)"
    echo "Probably the package for the version we want does not exist"
    echo '(conda will change the Python version even if it was explicitly declared)'
    exit 1
  fi

  # Check that the CUDA feature is working
  if [[ "$DESIRED_CUDA" == 'cpu' ]]; then
    if [[ -n "$(conda list torch | grep -o cuda)" ]]; then
      echo "The installed package is built for CUDA:: $(conda list torch)"
      exit 1
    fi
  elif [[ -z "$(conda list torch | grep -o cuda$cuda_dot)" ]]; then
    echo "The installed package doesn't seem to be built for CUDA $cuda_dot"
    echo "The full package is $(conda list torch)"
    exit 1
  fi
fi

if [[ "$PACKAGE_TYPE" == 'libtorch' ]]; then
  echo "For libtorch we only test that the download works"
  echo "The logfile for this run can be found at $log_url"
  exit 0
fi

# Quick smoke test that it works
echo "Smoke testing imports"
python -c 'import torch'
python -c 'from caffe2.python import core'

# Test that MKL is there
if [[ "$(uname)" == 'Darwin' && "$PACKAGE_TYPE" == wheel ]]; then
  echo 'Not checking for MKL on Darwin wheel packages'
else
  echo "Checking that MKL is available"
  python -c 'import torch; exit(0 if torch.backends.mkl.is_available() else 1)'
fi

# Test that CUDA builds are setup correctly
if [[ "$DESIRED_CUDA" != 'cpu' ]]; then
  # Test CUDA archs
  echo "Checking that CUDA archs are setup correctly"
  timeout 20 python -c 'import torch; torch.randn([3,5]).cuda()'

  # These have to run after CUDA is initialized
  echo "Checking that magma is available"
  python -c 'import torch; torch.rand(1).cuda(); exit(0 if torch.cuda.has_magma else 1)'

  echo "Checking that CuDNN is available"
  python -c 'import torch; exit(0 if torch.backends.cudnn.is_available() else 1)'
fi

# Loop through all shared libraries and
#  - Print out all the dependencies
#  - (Mac) check that there is no openblas dependency
#  - Check that there are no protobuf symbols
set +x
if [[ "$(uname)" == 'Darwin' ]]; then
  all_dylibs=($(find "$pyroot/envs/test/lib/python${DESIRED_PYTHON}/site-packages/torch/" -name '*.dylib'))
  for dylib in "${all_dylibs[@]}"; do
    echo "All dependencies of $dylib are $(otool -L $dylib) with rpath $(otool -l $dylib | grep LC_RPATH -A2)"

    # Check that OpenBlas is not linked to on Macs
    echo "Checking the OpenBLAS is not linked to"
    if [[ -n "$(otool -L $dylib | grep -i openblas)" ]]; then
      echo "ERROR: Found openblas as a dependency of $dylib"
      echo "Full dependencies is: $(otool -L $dylib)"
      exit 1
    fi

    # Check for protobuf symbols
    #proto_symbols="$(nm $dylib | grep protobuf)" || true
    #if [[ -n "$proto_symbols" ]]; then
    #  echo "ERROR: Detected protobuf symbols in $dylib"
    #  echo "Symbols are $proto_symbols"
    #  exit 1
    #fi
  done
else 
  if [[ "$PACKAGE_TYPE" == conda ]]; then
    all_libs=($(find "/opt/conda/envs/test/lib/python${py_dot}/site-packages/torch/" -name '*.so'))
  else
    all_libs=($(find "/opt/python/${py_long}/lib/python${py_dot}/site-packages/torch/" -name '*.so'))
  fi

  for lib in "${all_libs[@]}"; do
    echo "All dependencies of $lib are $(ldd $lib) with runpath $(objdump -p $lib | grep RUNPATH)"

    # Check for protobuf symbols
    #proto_symbols=$(nm $lib | grep protobuf) || true
    #if [[ -n "$proto_symbols" ]]; then
    #  echo "ERROR: Detected protobuf symbols in $lib"
    #  echo "Symbols are $proto_symbols"
    #  exit 1
    #fi
  done
fi

# Echo the location of the logs
echo "The logfile for this run can be found at $log_url"
