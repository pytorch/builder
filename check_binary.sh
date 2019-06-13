#!/bin/bash
set -eux -o pipefail

# This script checks the following things on binaries
# 1. The gcc abi matches DESIRED_DEVTOOLSET
# 2. MacOS binaries do not link against OpenBLAS
# 3. There are no protobuf symbols of any sort anywhere (turned off, because
#    this is currently not true)
# 4. Standard Python imports work
# 5. MKL is available everywhere except for MacOS wheels
# 6. CUDA is setup correctly and does not hang
# 7. Magma is available for CUDA builds
# 8. CuDNN is available for CUDA builds
#
# This script needs the env variables DESIRED_PYTHON, DESIRED_CUDA,
# DESIRED_DEVTOOLSET and PACKAGE_TYPE
#
# This script expects PyTorch to be installed into the active Python (the
# Python returned by `which python`). Or, if this is testing a libtorch
# Pythonless binary, then it expects to be in the root folder of the unzipped
# libtorch package. 


# The install root depends on both the package type and the os
# All MacOS packages use conda, even for the wheel packages.
if [[ "$PACKAGE_TYPE" == libtorch ]]; then
  install_root="$pwd"
else
  py_dot="${DESIRED_PYTHON:0:3}"
  install_root="$(dirname $(which python))/../lib/python${py_dot}/site-packages/torch/"
fi


###############################################################################
# Check GCC ABI
###############################################################################
echo "Checking that the gcc ABI is what we expect"
if [[ "$(uname)" != 'Darwin' ]]; then
  function is_expected() {
    if [[ "$DESIRED_DEVTOOLSET" == 'devtoolset7' ]]; then
      if [[ "$1" -gt 0 || "$1" == "ON" ]]; then
        echo 1
      fi
    else
      if [[ -z "$1" || "$1" == 0 || "$1" == "OFF" ]]; then
        echo 1
      fi
    fi
  }

  # First we check that the env var in TorchConfig.cmake is correct

  # We search for D_GLIBCXX_USE_CXX11_ABI=1 in torch/TorchConfig.cmake
  torch_config="${install_root}/share/cmake/Torch/TorchConfig.cmake"
  if [[ ! -f "$torch_config" ]]; then
    echo "No TorchConfig.cmake found!"
    ls -lah "$install_root/share/cmake/Torch"
    exit 1
  fi
  echo "Checking the TorchConfig.cmake"
  cat "$torch_config"

  # The sed call below is
  #   don't print lines by default (only print the line we want)
  # -n
  #   execute the following expression
  # e
  #   replace lines that match with the first capture group and print
  # s/.*D_GLIBCXX_USE_CXX11_ABI=\(.\)".*/\1/p
  #   any characters, D_GLIBCXX_USE_CXX11_ABI=, exactly one any character, a
  #   quote, any characters
  #   Note the exactly one single character after the '='. In the case that the
  #     variable is not set the '=' will be followed by a '"' immediately and the
  #     line will fail the match and nothing will be printed; this is what we
  #     want.  Otherwise it will capture the 0 or 1 after the '='.
  # /.*D_GLIBCXX_USE_CXX11_ABI=\(.\)".*/
  #   replace the matched line with the capture group and print
  # /\1/p
  actual_gcc_abi="$(sed -ne 's/.*D_GLIBCXX_USE_CXX11_ABI=\(.\)".*/\1/p' < "$torch_config")"
  if [[ "$(is_expected "$actual_gcc_abi")" != 1 ]]; then
    echo "gcc ABI $actual_gcc_abi not as expected."
    exit 1
  fi

  # We also check that there are[not] cxx11 symbols in libtorch
  echo "Checking that symbols in libtorch.so have the right gcc abi"
  libtorch="${install_root}/lib/libtorch.so"
  cxx11_symbols="$(nm "$libtorch" | c++filt | grep __cxx11 | wc -l)" || true
  if [[ "$(is_expected $cxx11_symbols)" != 1 ]]; then
    if [[ "$cxx11_symbols" == 0 ]]; then
      echo "No cxx11 symbols found, but there should be."
    else
      echo "Found cxx11 symbols but there shouldn't be. Dumping symbols"
      nm "$libtorch" | c++filt | grep __cxx11
    fi
    exit 1
  else
    echo "cxx11 symbols seem to be in order"
  fi
fi # if on Darwin

###############################################################################
# Check for no OpenBLAS
# TODO Check for no Protobuf symbols (not finished)
# Print *all* runtime dependencies
###############################################################################
# We have to loop through all shared libraries for this
if [[ "$(uname)" == 'Darwin' ]]; then
  all_dylibs=($(find "$install_root" -name '*.dylib'))
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
  all_libs=($(find "$install_root" -name '*.so'))
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


###############################################################################
# Check simple Python calls
###############################################################################
if [[ "$PACKAGE_TYPE" == 'libtorch' ]]; then
  # For libtorch testing is done. All further tests require Python
  exit 0
fi
python -c 'import torch'
python -c 'from caffe2.python import core'


###############################################################################
# Check for MKL
###############################################################################
if [[ "$(uname)" != 'Darwin' || "$PACKAGE_TYPE" != *wheel ]]; then
    echo "Checking that MKL is available"
    python -c 'import torch; exit(0 if torch.backends.mkl.is_available() else 1)'
fi


###############################################################################
# Check CUDA configured correctly
###############################################################################
# Skip these for Windows machines without GPUs
if [[ "$OSTYPE" == "msys" ]]; then
    GPUS=$(wmic path win32_VideoController get name)
    if [[ ! "$GPUS" == *NVIDIA* ]]; then
        echo "Skip CUDA tests for machines without a Nvidia GPU card"
        exit 0
    fi
fi

# Test that CUDA builds are setup correctly
if [[ "$DESIRED_CUDA" != 'cpu' ]]; then
    echo "Checking that CUDA archs are setup correctly"
    timeout 20 python -c 'import torch; torch.randn([3,5]).cuda()'

    # These have to run after CUDA is initialized

    echo "Checking that magma is available"
    python -c 'import torch; torch.rand(1).cuda(); exit(0 if torch.cuda.has_magma else 1)'

    echo "Checking that CuDNN is available"
    python -c 'import torch; exit(0 if torch.backends.cudnn.is_available() else 1)'
fi
