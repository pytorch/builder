#!/usr/bin/env bash

set -ex

export MAGMA_HOME=/opt/rocm/magma
# TODO: libtorch_cpu.so is broken when building with Debug info
export BUILD_DEBUG_INFO=0

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
ROCM_VERSION="$GPU_ARCH_VERSION"
echo "Using $ROCM_VERSION as determined by GPU_ARCH_VERSION"

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
    LIBDRM_PATH="/opt/amdgpu/lib64/libdrm.so.2"
    LIBDRM_AMDGPU_PATH="/opt/amdgpu/lib64/libdrm_amdgpu.so.1"
    MAYBE_LIB64=lib64
elif [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    LIBGOMP_PATH="/usr/lib/x86_64-linux-gnu/libgomp.so.1"
    LIBNUMA_PATH="/usr/lib/x86_64-linux-gnu/libnuma.so.1"
    LIBELF_PATH="/usr/lib/x86_64-linux-gnu/libelf.so.1"
    LIBTINFO_PATH="/lib/x86_64-linux-gnu/libtinfo.so.5"
    LIBDRM_PATH="/usr/lib/x86_64-linux-gnu/libdrm.so.2"
    LIBDRM_AMDGPU_PATH="/usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1"
    MAYBE_LIB64=lib
fi

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

if [[ $ROCM_INT -ge 50200 ]]; then
DEPS_LIST=(
    "/opt/rocm/lib/libMIOpen.so.1"
    "/opt/rocm/lib/libamdhip64.so.5"
    "/opt/rocm/lib/libhipblas.so.0"
    "/opt/rocm/lib/libhipfft.so"
    "/opt/rocm/lib/libhiprand.so.1"
    "/opt/rocm/lib/libhipsparse.so.0"
    "/opt/rocm/lib/libhsa-runtime64.so.1"
    "/opt/rocm/lib/libamd_comgr.so.2"
    "/opt/rocm/magma/lib/libmagma.so"
    "/opt/rocm/lib/librccl.so.1"
    "/opt/rocm/lib/librocblas.so.0"
    "/opt/rocm/lib/librocfft-device-0.so.0"
    "/opt/rocm/lib/librocfft-device-1.so.0"
    "/opt/rocm/lib/librocfft-device-2.so.0"
    "/opt/rocm/lib/librocfft-device-3.so.0"
    "/opt/rocm/lib/librocfft.so.0"
    "/opt/rocm/lib/librocm_smi64.so.5"
    "/opt/rocm/lib/librocrand.so.1"
    "/opt/rocm/lib/librocsolver.so.0"
    "/opt/rocm/lib/librocsparse.so.0"
    "/opt/rocm/lib/libroctracer64.so.1"
    "/opt/rocm/lib/libroctx64.so.1"
    "$LIBGOMP_PATH"
    "$LIBNUMA_PATH"
    "$LIBELF_PATH"
    "$LIBTINFO_PATH"
    "$LIBDRM_PATH"
    "$LIBDRM_AMDGPU_PATH"
)

DEPS_SONAME=(
    "libMIOpen.so.1"
    "libamdhip64.so.5"
    "libhipblas.so.0"
    "libhipfft.so"
    "libhiprand.so.1"
    "libhipsparse.so.0"
    "libhsa-runtime64.so.1"
    "libamd_comgr.so.2"
    "libmagma.so"
    "librccl.so.1"
    "librocblas.so.0"
    "librocfft-device-0.so.0"
    "librocfft-device-1.so.0"
    "librocfft-device-2.so.0"
    "librocfft-device-3.so.0"
    "librocfft.so.0"
    "librocm_smi64.so.5"
    "librocrand.so.1"
    "librocsolver.so.0"
    "librocsparse.so.0"
    "libroctracer64.so.1"
    "libroctx64.so.1"
    "libgomp.so.1"
    "libnuma.so.1"
    "libelf.so.1"
    "libtinfo.so.5"
    "libdrm.so.2"
    "libdrm_amdgpu.so.1"
)

DEPS_AUX_SRCLIST=(
    "/opt/rocm/lib/rocblas/library/Kernels.so-000-gfx803.hsaco"
    "/opt/rocm/lib/rocblas/library/Kernels.so-000-gfx900.hsaco"
    "/opt/rocm/lib/rocblas/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "/opt/rocm/lib/rocblas/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "/opt/rocm/lib/rocblas/library/Kernels.so-000-gfx90a-xnack-.hsaco"
    "/opt/rocm/lib/rocblas/library/Kernels.so-000-gfx90a-xnack+.hsaco"
    "/opt/rocm/lib/rocblas/library/Kernels.so-000-gfx1030.hsaco"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx803.co"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx900.co"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx906.co"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx908.co"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx90a.co"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx1030.co"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx803.dat"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx900.dat"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx906.dat"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx908.dat"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx90a.dat"
    "/opt/rocm/lib/rocblas/library/TensileLibrary_gfx1030.dat"
    "/opt/amdgpu/share/libdrm/amdgpu.ids"
)

DEPS_AUX_DSTLIST=(
    "lib/rocblas/library/Kernels.so-000-gfx803.hsaco"
    "lib/rocblas/library/Kernels.so-000-gfx900.hsaco"
    "lib/rocblas/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "lib/rocblas/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "lib/rocblas/library/Kernels.so-000-gfx90a-xnack-.hsaco"
    "lib/rocblas/library/Kernels.so-000-gfx90a-xnack+.hsaco"
    "lib/rocblas/library/Kernels.so-000-gfx1030.hsaco"
    "lib/rocblas/library/TensileLibrary_gfx803.co"
    "lib/rocblas/library/TensileLibrary_gfx900.co"
    "lib/rocblas/library/TensileLibrary_gfx906.co"
    "lib/rocblas/library/TensileLibrary_gfx908.co"
    "lib/rocblas/library/TensileLibrary_gfx90a.co"
    "lib/rocblas/library/TensileLibrary_gfx1030.co"
    "lib/rocblas/library/TensileLibrary_gfx803.dat"
    "lib/rocblas/library/TensileLibrary_gfx900.dat"
    "lib/rocblas/library/TensileLibrary_gfx906.dat"
    "lib/rocblas/library/TensileLibrary_gfx908.dat"
    "lib/rocblas/library/TensileLibrary_gfx90a.dat"
    "lib/rocblas/library/TensileLibrary_gfx1030.dat"
    "share/libdrm/amdgpu.ids"
)
elif [[ $ROCM_INT -ge 50100 ]]; then
DEPS_LIST=(
    "/opt/rocm/miopen/lib/libMIOpen.so.1"
    "/opt/rocm/hip/lib/libamdhip64.so.5"
    "/opt/rocm/hipblas/lib/libhipblas.so.0"
    "/opt/rocm/hipfft/lib/libhipfft.so"
    "/opt/rocm/lib/libhiprand.so.1"
    "/opt/rocm/hipsparse/lib/libhipsparse.so.0"
    "/opt/rocm/hsa/lib/libhsa-runtime64.so.1"
    "/opt/rocm/${MAYBE_LIB64}/libamd_comgr.so.2"
    "/opt/rocm/magma/lib/libmagma.so"
    "/opt/rocm/rccl/lib/librccl.so.1"
    "/opt/rocm/rocblas/lib/librocblas.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-0.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-1.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-2.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-3.so.0"
    "/opt/rocm/rocfft/lib/librocfft.so.0"
    "/opt/rocm/rocm_smi/lib/librocm_smi64.so.5"
    "/opt/rocm/lib/librocrand.so.1"
    "/opt/rocm/rocsolver/lib/librocsolver.so.0"
    "/opt/rocm/rocsparse/lib/librocsparse.so.0"
    "/opt/rocm/roctracer/lib/libroctracer64.so.1"
    "/opt/rocm/roctracer/lib/libroctx64.so.1"
    "$LIBGOMP_PATH"
    "$LIBNUMA_PATH"
    "$LIBELF_PATH"
    "$LIBTINFO_PATH"
    "$LIBDRM_PATH"
    "$LIBDRM_AMDGPU_PATH"
)

DEPS_SONAME=(
    "libMIOpen.so.1"
    "libamdhip64.so.5"
    "libhipblas.so.0"
    "libhipfft.so"
    "libhiprand.so.1"
    "libhipsparse.so.0"
    "libhsa-runtime64.so.1"
    "libamd_comgr.so.2"
    "libmagma.so"
    "librccl.so.1"
    "librocblas.so.0"
    "librocfft-device-0.so.0"
    "librocfft-device-1.so.0"
    "librocfft-device-2.so.0"
    "librocfft-device-3.so.0"
    "librocfft.so.0"
    "librocm_smi64.so.5"
    "librocrand.so.1"
    "librocsolver.so.0"
    "librocsparse.so.0"
    "libroctracer64.so.1"
    "libroctx64.so.1"
    "libgomp.so.1"
    "libnuma.so.1"
    "libelf.so.1"
    "libtinfo.so.5"
    "libdrm.so.2"
    "libdrm_amdgpu.so.1"
)

DEPS_AUX_SRCLIST=(
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx803.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx900.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx90a-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx90a-xnack+.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx1030.hsaco"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx803.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx900.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx906.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx908.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx90a.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx1030.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary.dat"
    "/opt/amdgpu/share/libdrm/amdgpu.ids"
)

DEPS_AUX_DSTLIST=(
    "lib/library/Kernels.so-000-gfx803.hsaco"
    "lib/library/Kernels.so-000-gfx900.hsaco"
    "lib/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx90a-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx90a-xnack+.hsaco"
    "lib/library/Kernels.so-000-gfx1030.hsaco"
    "lib/library/TensileLibrary_gfx803.co"
    "lib/library/TensileLibrary_gfx900.co"
    "lib/library/TensileLibrary_gfx906.co"
    "lib/library/TensileLibrary_gfx908.co"
    "lib/library/TensileLibrary_gfx90a.co"
    "lib/library/TensileLibrary_gfx1030.co"
    "lib/library/TensileLibrary.dat"
    "share/libdrm/amdgpu.ids"
)
elif [[ $ROCM_INT -ge 50000 ]]; then
DEPS_LIST=(
    "/opt/rocm/miopen/lib/libMIOpen.so.1"
    "/opt/rocm/hip/lib/libamdhip64.so.5"
    "/opt/rocm/hipblas/lib/libhipblas.so.0"
    "/opt/rocm/hipfft/lib/libhipfft.so"
    "/opt/rocm/hiprand/lib/libhiprand.so.1"
    "/opt/rocm/hipsparse/lib/libhipsparse.so.0"
    "/opt/rocm/hsa/lib/libhsa-runtime64.so.1"
    "/opt/rocm/${MAYBE_LIB64}/libamd_comgr.so.2"
    "/opt/rocm/magma/lib/libmagma.so"
    "/opt/rocm/rccl/lib/librccl.so.1"
    "/opt/rocm/rocblas/lib/librocblas.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-0.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-1.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-2.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-3.so.0"
    "/opt/rocm/rocfft/lib/librocfft.so.0"
    "/opt/rocm/rocm_smi/lib/librocm_smi64.so.5"
    "/opt/rocm/rocrand/lib/librocrand.so.1"
    "/opt/rocm/rocsolver/lib/librocsolver.so.0"
    "/opt/rocm/rocsparse/lib/librocsparse.so.0"
    "/opt/rocm/roctracer/lib/libroctracer64.so.1"
    "/opt/rocm/roctracer/lib/libroctx64.so.1"
    "$LIBGOMP_PATH"
    "$LIBNUMA_PATH"
    "$LIBELF_PATH"
    "$LIBTINFO_PATH"
    "$LIBDRM_PATH"
    "$LIBDRM_AMDGPU_PATH"
)

DEPS_SONAME=(
    "libMIOpen.so.1"
    "libamdhip64.so.5"
    "libhipblas.so.0"
    "libhipfft.so"
    "libhiprand.so.1"
    "libhipsparse.so.0"
    "libhsa-runtime64.so.1"
    "libamd_comgr.so.2"
    "libmagma.so"
    "librccl.so.1"
    "librocblas.so.0"
    "librocfft-device-0.so.0"
    "librocfft-device-1.so.0"
    "librocfft-device-2.so.0"
    "librocfft-device-3.so.0"
    "librocfft.so.0"
    "librocm_smi64.so.5"
    "librocrand.so.1"
    "librocsolver.so.0"
    "librocsparse.so.0"
    "libroctracer64.so.1"
    "libroctx64.so.1"
    "libgomp.so.1"
    "libnuma.so.1"
    "libelf.so.1"
    "libtinfo.so.5"
    "libdrm.so.2"
    "libdrm_amdgpu.so.1"
)

DEPS_AUX_SRCLIST=(
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx803.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx900.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx90a-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx90a-xnack+.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx1030.hsaco"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx803.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx900.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx906.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx908.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx90a.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx1030.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary.dat"
    "/opt/amdgpu/share/libdrm/amdgpu.ids"
)

DEPS_AUX_DSTLIST=(
    "lib/library/Kernels.so-000-gfx803.hsaco"
    "lib/library/Kernels.so-000-gfx900.hsaco"
    "lib/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx90a-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx90a-xnack+.hsaco"
    "lib/library/Kernels.so-000-gfx1030.hsaco"
    "lib/library/TensileLibrary_gfx803.co"
    "lib/library/TensileLibrary_gfx900.co"
    "lib/library/TensileLibrary_gfx906.co"
    "lib/library/TensileLibrary_gfx908.co"
    "lib/library/TensileLibrary_gfx90a.co"
    "lib/library/TensileLibrary_gfx1030.co"
    "lib/library/TensileLibrary.dat"
    "share/libdrm/amdgpu.ids"
)
elif [[ $ROCM_INT -ge 40500 ]]; then
DEPS_LIST=(
    "/opt/rocm/miopen/lib/libMIOpen.so.1"
    "/opt/rocm/hip/lib/libamdhip64.so.4"
    "/opt/rocm/hipblas/lib/libhipblas.so.0"
    "/opt/rocm/hipfft/lib/libhipfft.so"
    "/opt/rocm/hiprand/lib/libhiprand.so.1"
    "/opt/rocm/hipsparse/lib/libhipsparse.so.0"
    "/opt/rocm/hsa/lib/libhsa-runtime64.so.1"
    "/opt/rocm/${MAYBE_LIB64}/libamd_comgr.so.2"
    "/opt/rocm/magma/lib/libmagma.so"
    "/opt/rocm/rccl/lib/librccl.so.1"
    "/opt/rocm/rocblas/lib/librocblas.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-0.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-1.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-2.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-3.so.0"
    "/opt/rocm/rocfft/lib/librocfft.so.0"
    "/opt/rocm/rocm_smi/lib/librocm_smi64.so.4"
    "/opt/rocm/rocrand/lib/librocrand.so.1"
    "/opt/rocm/rocsolver/lib/librocsolver.so.0"
    "/opt/rocm/rocsparse/lib/librocsparse.so.0"
    "/opt/rocm/roctracer/lib/libroctracer64.so.1"
    "/opt/rocm/roctracer/lib/libroctx64.so.1"
    "$LIBGOMP_PATH"
    "$LIBNUMA_PATH"
    "$LIBELF_PATH"
    "$LIBTINFO_PATH"
    "$LIBDRM_PATH"
    "$LIBDRM_AMDGPU_PATH"
)

DEPS_SONAME=(
    "libMIOpen.so.1"
    "libamdhip64.so.4"
    "libhipblas.so.0"
    "libhipfft.so"
    "libhiprand.so.1"
    "libhipsparse.so.0"
    "libhsa-runtime64.so.1"
    "libamd_comgr.so.2"
    "libmagma.so"
    "librccl.so.1"
    "librocblas.so.0"
    "librocfft-device-0.so.0"
    "librocfft-device-1.so.0"
    "librocfft-device-2.so.0"
    "librocfft-device-3.so.0"
    "librocfft.so.0"
    "librocm_smi64.so.4"
    "librocrand.so.1"
    "librocsolver.so.0"
    "librocsparse.so.0"
    "libroctracer64.so.1"
    "libroctx64.so.1"
    "libgomp.so.1"
    "libnuma.so.1"
    "libelf.so.1"
    "libtinfo.so.5"
    "libdrm.so.2"
    "libdrm_amdgpu.so.1"
)

DEPS_AUX_SRCLIST=(
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx803.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx900.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx90a-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx90a-xnack+.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx1030.hsaco"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx803.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx900.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx906.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx908.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx90a.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx1030.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary.dat"
    "/opt/amdgpu/share/libdrm/amdgpu.ids"
)

DEPS_AUX_DSTLIST=(
    "lib/library/Kernels.so-000-gfx803.hsaco"
    "lib/library/Kernels.so-000-gfx900.hsaco"
    "lib/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx90a-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx90a-xnack+.hsaco"
    "lib/library/Kernels.so-000-gfx1030.hsaco"
    "lib/library/TensileLibrary_gfx803.co"
    "lib/library/TensileLibrary_gfx900.co"
    "lib/library/TensileLibrary_gfx906.co"
    "lib/library/TensileLibrary_gfx908.co"
    "lib/library/TensileLibrary_gfx90a.co"
    "lib/library/TensileLibrary_gfx1030.co"
    "lib/library/TensileLibrary.dat"
    "share/libdrm/amdgpu.ids"
)
elif [[ $ROCM_INT -ge 40300 ]]; then
DEPS_LIST=(
    "/opt/rocm/miopen/lib/libMIOpen.so.1"
    "/opt/rocm/hip/lib/libamdhip64.so.4"
    "/opt/rocm/hipblas/lib/libhipblas.so.0"
    "/opt/rocm/hipfft/lib/libhipfft.so"
    "/opt/rocm/hiprand/lib/libhiprand.so.1"
    "/opt/rocm/hipsparse/lib/libhipsparse.so.0"
    "/opt/rocm/hsa/lib/libhsa-runtime64.so.1"
    "/opt/rocm/${MAYBE_LIB64}/libamd_comgr.so.2"
    "/opt/rocm/${MAYBE_LIB64}/libhsakmt.so.1"
    "/opt/rocm/magma/lib/libmagma.so"
    "/opt/rocm/rccl/lib/librccl.so.1"
    "/opt/rocm/rocblas/lib/librocblas.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-misc.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-single.so.0"
    "/opt/rocm/rocfft/lib/librocfft-device-double.so.0"
    "/opt/rocm/rocfft/lib/librocfft.so.0"
    "/opt/rocm/rocrand/lib/librocrand.so.1"
    "/opt/rocm/rocsolver/lib/librocsolver.so.0"
    "/opt/rocm/rocsparse/lib/librocsparse.so.0"
    "/opt/rocm/roctracer/lib/libroctracer64.so.1"
    "/opt/rocm/roctracer/lib/libroctx64.so.1"
    "$LIBGOMP_PATH"
    "$LIBNUMA_PATH"
    "$LIBELF_PATH"
    "$LIBTINFO_PATH"
)

DEPS_SONAME=(
    "libMIOpen.so.1"
    "libamdhip64.so.4"
    "libhipblas.so.0"
    "libhipfft.so"
    "libhiprand.so.1"
    "libhipsparse.so.0"
    "libhsa-runtime64.so.1"
    "libamd_comgr.so.2"
    "libhsakmt.so.1"
    "libmagma.so"
    "librccl.so.1"
    "librocblas.so.0"
    "librocfft-device-misc.so.0"
    "librocfft-device-single.so.0"
    "librocfft-device-double.so.0"
    "librocfft.so.0"
    "librocrand.so.1"
    "librocsolver.so.0"
    "librocsparse.so.0"
    "libroctracer64.so.1"
    "libroctx64.so.1"
    "libgomp.so.1"
    "libnuma.so.1"
    "libelf.so.1"
    "libtinfo.so.5"
)

DEPS_AUX_SRCLIST=(
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx803.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx900.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx803.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx900.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx906.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx908.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary.dat"
)

DEPS_AUX_DSTLIST=(
    "lib/library/Kernels.so-000-gfx803.hsaco"
    "lib/library/Kernels.so-000-gfx900.hsaco"
    "lib/library/Kernels.so-000-gfx906-xnack-.hsaco"
    "lib/library/Kernels.so-000-gfx908-xnack-.hsaco"
    "lib/library/TensileLibrary_gfx803.co"
    "lib/library/TensileLibrary_gfx900.co"
    "lib/library/TensileLibrary_gfx906.co"
    "lib/library/TensileLibrary_gfx908.co"
    "lib/library/TensileLibrary.dat"
)
fi

echo "PYTORCH_ROCM_ARCH: ${PYTORCH_ROCM_ARCH}"

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
if [[ -z "$BUILD_PYTHONLESS" ]]; then
    BUILD_SCRIPT=build_common.sh
else
    BUILD_SCRIPT=build_libtorch.sh
fi
source $SCRIPTPATH/${BUILD_SCRIPT}
