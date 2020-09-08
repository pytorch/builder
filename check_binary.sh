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
  # NOTE: Only $PWD works on both CentOS and Ubuntu
  install_root="$PWD"
else
  py_dot="${DESIRED_PYTHON:0:3}"
  install_root="$(dirname $(which python))/../lib/python${py_dot}/site-packages/torch/"
fi

if [[ "$DESIRED_CUDA" != 'cpu' && "$DESIRED_CUDA" != 'rocm3.7' ]]; then
  # cu90, cu92, cu100, cu101
  if [[ ${#DESIRED_CUDA} -eq 4 ]]; then
    CUDA_VERSION="${DESIRED_CUDA:2:1}.${DESIRED_CUDA:3:1}"
  elif [[ ${#DESIRED_CUDA} -eq 5 ]]; then
    CUDA_VERSION="${DESIRED_CUDA:2:2}.${DESIRED_CUDA:4:1}"
  fi
  echo "Using CUDA $CUDA_VERSION as determined by DESIRED_CUDA"

  # Switch `/usr/local/cuda` to the desired CUDA version
  rm -rf /usr/local/cuda || true
  ln -s "/usr/local/cuda-${CUDA_VERSION}" /usr/local/cuda
  export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
fi

###############################################################################
# Check GCC ABI
###############################################################################

# NOTE [ Building libtorch with old vs. new gcc ABI ]
#
# Packages built with one version of ABI could not be linked against by client
# C++ libraries that were compiled using the other version of ABI. Since both
# gcc ABIs are still common in the wild, we need to support both ABIs. Currently:
#
# - All the nightlies built on CentOS 7 + devtoolset7 use the old gcc ABI.
# - All the nightlies built on Ubuntu 16.04 + gcc 5.4 use the new gcc ABI.

echo "Checking that the gcc ABI is what we expect"
if [[ "$(uname)" != 'Darwin' ]]; then
  function is_expected() {
    if [[ "$DESIRED_DEVTOOLSET" == *"cxx11-abi"* ]]; then
      if [[ "$1" -gt 0 || "$1" == "ON " ]]; then
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

  # We also check that there are [not] cxx11 symbols in libtorch
  #
  # To check whether it is using cxx11 ABI, check non-existence of symbol:
  PRE_CXX11_SYMBOLS=(
    "std::basic_string"
    "std::list"
  )
  # To check whether it is using pre-cxx11 ABI, check non-existence of symbol:
  CXX11_SYMBOLS=(
    "std::__cxx11::basic_string"
    "std::__cxx11::list"
  )
  # NOTE: Checking the above symbols in all namespaces doesn't work, because
  # devtoolset7 always produces some cxx11 symbols even if we build with old ABI,
  # and CuDNN always has pre-cxx11 symbols even if we build with new ABI using gcc 5.4.
  # Instead, we *only* check the above symbols in the following namespaces:
  LIBTORCH_NAMESPACE_LIST=(
    "c10::"
    "at::"
    "caffe2::"
    "torch::"
  )
  echo "Checking that symbols in libtorch.so have the right gcc abi"
  grep_symbols () {
    symbols=("$@")
    for namespace in "${LIBTORCH_NAMESPACE_LIST[@]}"
    do
      for symbol in "${symbols[@]}"
      do
        nm "$lib" | c++filt | grep " $namespace".*$symbol
      done
    done
  }
  check_lib_symbols_for_abi_correctness () {
    lib=$1
    echo "lib: " $lib
    if [[ "$DESIRED_DEVTOOLSET" == *"cxx11-abi"* ]]; then
      num_pre_cxx11_symbols=$(grep_symbols "${PRE_CXX11_SYMBOLS[@]}" | wc -l) || true
      echo "num_pre_cxx11_symbols: " $num_pre_cxx11_symbols
      if [[ "$num_pre_cxx11_symbols" -gt 0 ]]; then
        echo "Found pre-cxx11 symbols but there shouldn't be. Dumping symbols"
        grep_symbols "${PRE_CXX11_SYMBOLS[@]}"
        exit 1
      fi
      num_cxx11_symbols=$(grep_symbols "${CXX11_SYMBOLS[@]}" | wc -l) || true
      echo "num_cxx11_symbols: " $num_cxx11_symbols
      if [[ "$num_cxx11_symbols" -lt 1000 ]]; then
        echo "Didn't find enough cxx11 symbols. Aborting."
        exit 1
      fi
    else
      num_cxx11_symbols=$(grep_symbols "${CXX11_SYMBOLS[@]}" | wc -l) || true
      echo "num_cxx11_symbols: " $num_cxx11_symbols
      if [[ "$num_cxx11_symbols" -gt 0 ]]; then
        echo "Found cxx11 symbols but there shouldn't be. Dumping symbols"
        grep_symbols "${CXX11_SYMBOLS[@]}"
        exit 1
      fi
      num_pre_cxx11_symbols=$(grep_symbols "${PRE_CXX11_SYMBOLS[@]}" | wc -l) || true
      echo "num_pre_cxx11_symbols: " $num_pre_cxx11_symbols
      if [[ "$num_pre_cxx11_symbols" -lt 1000 ]]; then
        echo "Didn't find enough pre-cxx11 symbols. Aborting."
        exit 1
      fi
    fi
  }
  # After https://github.com/pytorch/pytorch/pull/29731 most of the real
  # libtorch code will live in libtorch_cpu, not libtorch, so cxx11
  # symbol counting won't work on libtorch (since there's nothing in
  # it.)  Fortunately, libtorch_cpu.so doesn't exist prior to this PR,
  # so just test if the file exists and use it if it does.
  if [ -f "${install_root}/lib/libtorch_cpu.so" ]; then
    libtorch="${install_root}/lib/libtorch_cpu.so"
  else
    libtorch="${install_root}/lib/libtorch.so"
  fi
  check_lib_symbols_for_abi_correctness $libtorch

  echo "cxx11 symbols seem to be in order"
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

TEST_CODE_DIR="$(dirname ${BASH_SOURCE[0]})/test_example_code"
build_and_run_example_cpp () {
  if [[ "$DESIRED_DEVTOOLSET" == *"cxx11-abi"* ]]; then
    GLIBCXX_USE_CXX11_ABI=1
  else
    GLIBCXX_USE_CXX11_ABI=0
  fi
  REF_LIB="-Wl,-R${install_root}/lib"
  if [[ "$(uname)" == 'Darwin' ]]; then
    REF_LIB="-Wl,-rpath ${install_root}/lib"
  fi
  ADDITIONAL_LINKER_FLAGS=""
  if [[ "$(uname)" == 'Linux' ]]; then
    ADDITIONAL_LINKER_FLAGS="-Wl,--no-as-needed"
  fi
  C10_LINK_FLAGS=""
  if [ -f "${install_root}/lib/libc10.so" ] || [ -f "${install_root}/lib/libc10.dylib" ]; then
    C10_LINK_FLAGS="-lc10"
  fi
  TORCH_CPU_LINK_FLAGS=""
  if [ -f "${install_root}/lib/libtorch_cpu.so" ] || [ -f "${install_root}/lib/libtorch_cpu.dylib" ]; then
    TORCH_CPU_LINK_FLAGS="-ltorch_cpu"
  fi
  TORCH_CUDA_LINK_FLAGS=""
  if [ -f "${install_root}/lib/libtorch_cuda.so" ] || [ -f "${install_root}/lib/libtorch_cuda.dylib" ]; then
    TORCH_CUDA_LINK_FLAGS="-ltorch_cuda"
  fi
  g++ ${TEST_CODE_DIR}/$1.cpp -I${install_root}/include -I${install_root}/include/torch/csrc/api/include -D_GLIBCXX_USE_CXX11_ABI=$GLIBCXX_USE_CXX11_ABI -std=gnu++14 -L${install_root}/lib ${REF_LIB} ${ADDITIONAL_LINKER_FLAGS} -ltorch $TORCH_CPU_LINK_FLAGS $TORCH_CUDA_LINK_FLAGS $C10_LINK_FLAGS -o $1
  ./$1
}

build_example_cpp_with_incorrect_abi () {
  if [[ "$DESIRED_DEVTOOLSET" == *"cxx11-abi"* ]]; then
    GLIBCXX_USE_CXX11_ABI=0
  else
    GLIBCXX_USE_CXX11_ABI=1
  fi
  set +e
  REF_LIB="-Wl,-R${install_root}/lib"
  if [[ "$(uname)" == 'Darwin' ]]; then
    REF_LIB="-Wl,-rpath ${install_root}/lib"
  fi
  ADDITIONAL_LINKER_FLAGS=""
  if [[ "$(uname)" == 'Linux' ]]; then
    ADDITIONAL_LINKER_FLAGS="-Wl,--no-as-needed"
  fi
  C10_LINK_FLAGS=""
  if [ -f "${install_root}/lib/libc10.so" ] || [ -f "${install_root}/lib/libc10.dylib" ]; then
    C10_LINK_FLAGS="-lc10"
  fi
  TORCH_CPU_LINK_FLAGS=""
  if [ -f "${install_root}/lib/libtorch_cpu.so" ] || [ -f "${install_root}/lib/libtorch_cpu.dylib" ]; then
    TORCH_CPU_LINK_FLAGS="-ltorch_cpu"
  fi
  TORCH_CUDA_LINK_FLAGS=""
  if [ -f "${install_root}/lib/libtorch_cuda.so" ] || [ -f "${install_root}/lib/libtorch_cuda.dylib" ]; then
    TORCH_CUDA_LINK_FLAGS="-ltorch_cuda"
  fi
  g++ ${TEST_CODE_DIR}/$1.cpp -I${install_root}/include -I${install_root}/include/torch/csrc/api/include -D_GLIBCXX_USE_CXX11_ABI=$GLIBCXX_USE_CXX11_ABI -std=gnu++14 -L${install_root}/lib ${REF_LIB} ${ADDITIONAL_LINKER_FLAGS} -ltorch $TORCH_CPU_LINK_FLAGS $TORCH_CUDA_LINK_FLAGS $C10_LINK_FLAGS -o $1
  ERRCODE=$?
  set -e
  if [ "$ERRCODE" -eq "0" ]; then
    echo "Building example with incorrect ABI didn't throw error. Aborting."
    exit 1
  else
    echo "Building example with incorrect ABI throws expected error. Proceeding."
  fi
}

###############################################################################
# Check simple Python/C++ calls
###############################################################################
if [[ "$PACKAGE_TYPE" == 'libtorch' ]]; then
  build_and_run_example_cpp simple-torch-test
  # `_GLIBCXX_USE_CXX11_ABI` is always ignored by gcc in devtoolset7, so we test
  # the expected failure case for Ubuntu 16.04 + gcc 5.4 only.
  if [[ "$DESIRED_DEVTOOLSET" == *"cxx11-abi"* ]]; then
    build_example_cpp_with_incorrect_abi simple-torch-test
  fi
else
  pushd /tmp
  python -c 'import torch'
  python -c 'from caffe2.python import core'
  popd
fi


###############################################################################
# Check for MKL
###############################################################################

if [[ "$PACKAGE_TYPE" == 'libtorch' ]]; then
  echo "Checking that MKL is available"
  build_and_run_example_cpp check-torch-mkl
else
  if [[ "$(uname)" != 'Darwin' || "$PACKAGE_TYPE" != *wheel ]]; then
    echo "Checking that MKL is available"
    pushd /tmp
    python -c 'import torch; exit(0 if torch.backends.mkl.is_available() else 1)'
    popd
  fi
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
  if [[ "$PACKAGE_TYPE" == 'libtorch' ]]; then
    build_and_run_example_cpp check-torch-cuda
  else
    pushd /tmp
    echo "Checking that CUDA archs are setup correctly"
    timeout 20 python -c 'import torch; torch.randn([3,5]).cuda()'

    # These have to run after CUDA is initialized

    echo "Checking that magma is available"
    python -c 'import torch; torch.rand(1).cuda(); exit(0 if torch.cuda.has_magma else 1)'

    echo "Checking that CuDNN is available"
    python -c 'import torch; exit(0 if torch.backends.cudnn.is_available() else 1)'
    popd
  fi # if libtorch
fi # if cuda
