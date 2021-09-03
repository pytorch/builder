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
    LIBTINFO_PATH="/usr/lib64/libtinfo.so.5"
elif [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    LIBGOMP_PATH="/usr/lib/x86_64-linux-gnu/libgomp.so.1"
    LIBNUMA_PATH="/usr/lib/x86_64-linux-gnu/libnuma.so.1"
    LIBELF_PATH="/usr/lib/x86_64-linux-gnu/libelf.so.1"
    LIBTINFO_PATH="/lib/x86_64-linux-gnu/libtinfo.so.5"
fi

# NOTE: Some ROCm versions have identical dependencies, or very close deps.
# We conditionalize as generically as possible, capturing only what changes
# from version to version.

# To make version comparison easier, create an integer representation.
ROCM_VERSION_CLEAN=$(echo ${ROCM_VERSION} | sed s/rocm//)
save_IFS="$IFS"
IFS=. ROCM_VERSION_ARRAY=(${ROCM_VERSION_CLEAN})
IFS="$save_IFS"
if [[ ${#ROCM_VERSION_ARRAY[@]} == 2 ]]; then
    ROCM_VERSION_MAJOR=${ROCM_VERSION_ARRAY[0]}
    ROCM_VERSION_MINOR=${ROCM_VERSION_ARRAY[1]}
    ROCM_VERSION_PATCH=0
elif [[ ${#ROCM_VERSION_ARRAY[@]} == 3 ]]; then
    ROCM_VERSION_MAJOR=${ROCM_VERSION_ARRAY[0]}
    ROCM_VERSION_MINOR=${ROCM_VERSION_ARRAY[1]}
    ROCM_VERSION_PATCH=${ROCM_VERSION_ARRAY[2]}
else
    echo "Unhandled ROCM_VERSION ${ROCM_VERSION}"
    exit 1
fi
ROCM_INT=$(($ROCM_VERSION_MAJOR * 10000 + $ROCM_VERSION_MINOR * 100 + $ROCM_VERSION_PATCH))

# rocm3.8 and later use TensileLibrary.dat
if [[ $ROCM_INT -ge 30800 ]]; then
    TENSILE_LIBRARY_NAME=TensileLibrary.dat
else
    TENSILE_LIBRARY_NAME=TensileLibrary.yaml
fi

# in rocm3.9, libamd_comgr path changed from lib to lib64
if [[ $ROCM_INT -ge 30900 ]]; then
    COMGR_LIBDIR="lib64"
else
    COMGR_LIBDIR="lib"
fi

# in rocm4.0, libamdhip64.so.3 changed to *.so.4
if [[ $ROCM_INT -ge 40000 ]]; then
    LIBAMDHIP64=libamdhip64.so.4
else
    LIBAMDHIP64=libamdhip64.so.3
fi;

# in rocm4.1, libamd_comgr.so.1 changed to *.so.2
# hipfft is a new package, separate from rocfft
if [[ $ROCM_INT -ge 40100 ]]; then
    LIBAMDCOMGR=libamd_comgr.so.2
    KERNELGFX906=gfx906-xnack-
    KERNELGFX908=gfx908-xnack-
    HIPFFT_DEP=/opt/rocm/hipfft/lib/libhipfft.so
    HIPFFT_SO=libhipfft.so
else
    LIBAMDCOMGR=libamd_comgr.so.1
    KERNELGFX906=gfx906
    KERNELGFX908=gfx908
    HIPFFT_DEP=
    HIPFFT_SO=
fi;

DEPS_LIST=(
    "/opt/rocm/miopen/lib/libMIOpen.so.1"
    "/opt/rocm/hip/lib/$LIBAMDHIP64"
    "/opt/rocm/hipblas/lib/libhipblas.so.0"
    ${HIPFFT_DEP}
    "/opt/rocm/hiprand/lib/libhiprand.so.1"
    "/opt/rocm/hipsparse/lib/libhipsparse.so.0"
    "/opt/rocm/hsa/lib/libhsa-runtime64.so.1"
    "/opt/rocm/${COMGR_LIBDIR}/${LIBAMDCOMGR}"
    "/opt/rocm/lib64/libhsakmt.so.1"
    "/opt/rocm/magma/lib/libmagma.so"
    "/opt/rocm/rccl/lib/librccl.so.1"
    "/opt/rocm/rocblas/lib/librocblas.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device.so.0"
    "/opt/rocm/rocfft/lib/librocfft.so.0"
    "/opt/rocm/rocrand/lib/librocrand.so.1"
    "/opt/rocm/rocsolver/lib/librocsolver.so.0"
    "/opt/rocm/rocsparse/lib/librocsparse.so.0"
    "/opt/rocm/roctracer/lib/libroctx64.so.1"
    "$LIBGOMP_PATH"
    "$LIBNUMA_PATH"
    "$LIBELF_PATH"
    "$LIBTINFO_PATH"
)

DEPS_SONAME=(
    "libMIOpen.so.1"
    "$LIBAMDHIP64"
    "libhipblas.so.0"
    ${HIPFFT_SO}
    "libhiprand.so.1"
    "libhipsparse.so.0"
    "libhsa-runtime64.so.1"
    "${LIBAMDCOMGR}"
    "libhsakmt.so.1"
    "libmagma.so"
    "librccl.so.1"
    "librocblas.so.0"
    "librocfft-device.so.0"
    "librocfft.so.0"
    "librocrand.so.1"
    "librocsolver.so.0"
    "librocsparse.so.0"
    "libroctx64.so.1"
    "libgomp.so.1"
    "libnuma.so.1"
    "libelf.so.1"
    "libtinfo.so.5"
)

DEPS_AUX_SRCLIST=(
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx803.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx900.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-${KERNELGFX906}.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-${KERNELGFX908}.hsaco"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx803.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx900.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx906.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx908.co"
    "/opt/rocm/rocblas/lib/library/$TENSILE_LIBRARY_NAME"
)

DEPS_AUX_DSTLIST=(
    "lib/library/Kernels.so-000-gfx803.hsaco"
    "lib/library/Kernels.so-000-gfx900.hsaco"
    "lib/library/Kernels.so-000-${KERNELGFX906}.hsaco"
    "lib/library/Kernels.so-000-${KERNELGFX908}.hsaco"
    "lib/library/TensileLibrary_gfx803.co"
    "lib/library/TensileLibrary_gfx900.co"
    "lib/library/TensileLibrary_gfx906.co"
    "lib/library/TensileLibrary_gfx908.co"
    "lib/library/$TENSILE_LIBRARY_NAME"
)

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
if [[ -z "$BUILD_PYTHONLESS" ]]; then
    BUILD_SCRIPT=build_common.sh
else
    BUILD_SCRIPT=build_libtorch.sh
fi
source $SCRIPTPATH/${BUILD_SCRIPT}
