#!/usr/bin/env bash

set -ex

export MAGMA_HOME=/opt/rocm/magma

# TODO Are these all used/needed?
export TH_BINARY_BUILD=1
export USE_STATIC_CUDNN=1
export USE_STATIC_NCCL=1
export ATEN_STATIC_CUDA=1
export USE_CUDA_STATIC_LINK=1
export INSTALL_TEST=0 # dont install test binaries into site-packages

# Keep an array of cmake variables to add to
if [[ -z "$CMAKE_ARGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build()
    CMAKE_ARGS=()
fi
if [[ -z "$EXTRA_CAFFE2_CMAKE_FLAGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build_caffe2()
    EXTRA_CAFFE2_CMAKE_FLAGS=()
fi

# Determine ROCm version and architectures to build for
#
# NOTE: We should first check `DESIRED_CUDA` when determining `ROCM_VERSION`
if [[ -n "$DESIRED_CUDA" ]]; then
    if ! echo "${DESIRED_CUDA}"| grep "^rocm" >/dev/null 2>/dev/null; then
        export DESIRED_CUDA="rocm${DESIRED_CUDA}"
    fi
    # rocm3.7, rocm3.5.1
    ROCM_VERSION="$DESIRED_CUDA"
    echo "Using $ROCM_VERSION as determined by DESIRED_CUDA"
else
    echo "Must set DESIRED_CUDA"
    exit 1
fi

# NOTE: PYTORCH_ROCM_ARCH defaults to all supported archs in pytorch's LoadHIP.cmake
# e.g., set(PYTORCH_ROCM_ARCH gfx803;gfx900;gfx906;gfx908)
# No need to set here.

# Package directories
WHEELHOUSE_DIR="wheelhouse$ROCM_VERSION"
LIBTORCH_HOUSE_DIR="libtorch_house$ROCM_VERSION"
if [[ -z "$PYTORCH_FINAL_PACKAGE_DIR" ]]; then
    if [[ -z "$BUILD_PYTHONLESS" ]]; then
        PYTORCH_FINAL_PACKAGE_DIR="/remote/wheelhouse$ROCM_VERSION"
    else
        PYTORCH_FINAL_PACKAGE_DIR="/remote/libtorch_house$ROCM_VERSION"
    fi
fi
mkdir -p "$PYTORCH_FINAL_PACKAGE_DIR" || true

OS_NAME=`awk -F= '/^NAME/{print $2}' /etc/os-release`
if [[ "$OS_NAME" == *"CentOS Linux"* ]]; then
    LIBGOMP_PATH="/usr/lib64/libgomp.so.1"
    LIBNUMA_PATH="/usr/lib64/libnuma.so.1"
    LIBELF_PATH="/usr/lib64/libelf.so.1"
elif [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    LIBGOMP_PATH="/usr/lib/x86_64-linux-gnu/libgomp.so.1"
    LIBNUMA_PATH="/usr/lib/x86_64-linux-gnu/libnuma.so.1"
    LIBELF_PATH="/usr/lib/x86_64-linux-gnu/libelf.so.1"
fi

# rocm3.8 and later use TensileLibrary.dat
if [[ $ROCM_VERSION == "rocm3.7" ]]; then
    TENSILE_LIBRARY_NAME=TensileLibrary.yaml
else
    TENSILE_LIBRARY_NAME=TensileLibrary.dat
fi

# in rocm3.9, libamd_comgr path changed from lib to lib64
if [[ $ROCM_VERSION == "rocm3.7" || $ROCM_VERSION == "rocm3.8" ]]; then
    COMGR_LIBDIR="lib"
else
    COMGR_LIBDIR="lib64"
fi

# in rocm4.0, libamdhip64.so.3 changed to *.so.4
if [[ $ROCM_VERSION == "rocm4.0" ]]; then
    LIBAMDHIP64=libamdhip64.so.4
else
    LIBAMDHIP64=libamdhip64.so.3
fi;

# NOTE: Some ROCm versions have identical dependencies, or very close deps.
# To avoid copy/paste mistakes, version condition branches are combined.
if [[ $ROCM_VERSION == "rocm3.7" || $ROCM_VERSION == "rocm3.8" || $ROCM_VERSION == "rocm3.9" || $ROCM_VERSION == "rocm3.10"  || $ROCM_VERSION == "rocm4.0" ]]; then

DEPS_LIST=(
    "/opt/rocm/miopen/lib/libMIOpen.so.1"
    "/opt/rocm/hip/lib/$LIBAMDHIP64"
    "/opt/rocm/hiprand/lib/libhiprand.so.1"
    "/opt/rocm/hipsparse/lib/libhipsparse.so.0"
    "/opt/rocm/hsa/lib/libhsa-runtime64.so.1"
    "/opt/rocm/${COMGR_LIBDIR}/libamd_comgr.so.1"
    "/opt/rocm/lib64/libhsakmt.so.1"
    "/opt/rocm/magma/lib/libmagma.so"
    "/opt/rocm/rccl/lib/librccl.so.1"
    "/opt/rocm/rocblas/lib/librocblas.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device.so.0"
    "/opt/rocm/rocfft/lib/librocfft.so.0"
    "/opt/rocm/rocrand/lib/librocrand.so.1"
    "/opt/rocm/rocsparse/lib/librocsparse.so.0"
    "/opt/rocm/roctracer/lib/libroctx64.so.1"
    "$LIBGOMP_PATH"
    "$LIBNUMA_PATH"
    "$LIBELF_PATH"
)

DEPS_SONAME=(
    "libMIOpen.so.1"
    "$LIBAMDHIP64"
    "libhiprand.so.1"
    "libhipsparse.so.0"
    "libhsa-runtime64.so.1"
    "libamd_comgr.so.1"
    "libhsakmt.so.1"
    "libmagma.so"
    "librccl.so.1"
    "librocblas.so.0"
    "librocfft-device.so.0"
    "librocfft.so.0"
    "librocrand.so.1"
    "librocsparse.so.0"
    "libroctx64.so.1"
    "libgomp.so.1"
    "libnuma.so.1"
    "libelf.so.1"
)

DEPS_AUX_SRCLIST=(
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx803.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx900.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx906.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx908.hsaco"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx803.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx900.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx906.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx908.co"
    "/opt/rocm/rocblas/lib/library/$TENSILE_LIBRARY_NAME"
)

DEPS_AUX_DSTLIST=(
    "lib/library/Kernels.so-000-gfx803.hsaco"
    "lib/library/Kernels.so-000-gfx900.hsaco"
    "lib/library/Kernels.so-000-gfx906.hsaco"
    "lib/library/Kernels.so-000-gfx908.hsaco"
    "lib/library/TensileLibrary_gfx803.co"
    "lib/library/TensileLibrary_gfx900.co"
    "lib/library/TensileLibrary_gfx906.co"
    "lib/library/TensileLibrary_gfx908.co"
    "lib/library/$TENSILE_LIBRARY_NAME"
)

else
    echo "Unknown ROCm version $ROCM_VERSION"
    exit 1
fi

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
if [[ -z "$BUILD_PYTHONLESS" ]]; then
    BUILD_SCRIPT=build_common.sh
else
    BUILD_SCRIPT=build_libtorch.sh
fi
source $SCRIPTPATH/${BUILD_SCRIPT}
