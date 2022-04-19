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
    MAYBE_LIB64=lib64
elif [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    LIBGOMP_PATH="/usr/lib/x86_64-linux-gnu/libgomp.so.1"
    LIBNUMA_PATH="/usr/lib/x86_64-linux-gnu/libnuma.so.1"
    LIBELF_PATH="/usr/lib/x86_64-linux-gnu/libelf.so.1"
    LIBTINFO_PATH="/lib/x86_64-linux-gnu/libtinfo.so.5"
    MAYBE_LIB64=lib
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

# in rocm4.0, libamdhip64.so.3 changed to *.so.4
if [[ $ROCM_INT -ge 50000 ]]; then
    LIBAMDHIP64=libamdhip64.so.5
elif [[ $ROCM_INT -ge 40000 ]]; then
    LIBAMDHIP64=libamdhip64.so.4
else
    LIBAMDHIP64=libamdhip64.so.3
fi;

# in rocm4.1, libamd_comgr.so.1 changed to *.so.2
# hipfft is a new package, separate from rocfft
if [[ $ROCM_INT -ge 40500 ]]; then
    LIBAMDCOMGR=libamd_comgr.so.2
    SRCLIST_PATH="/opt/rocm/rocblas/lib/library/"
    DSTLIST_PATH="lib/library/"
    KERNELGFX906=gfx906-xnack-
    KERNELGFX908=gfx908-xnack-
    KERNELGFX90A="Kernels.so-000-gfx90a-xnack-.hsaco"
    KERNELGFX90A_="Kernels.so-000-gfx90a-xnack+.hsaco"
    KERNELGFX1030="Kernels.so-000-gfx1030.hsaco"
    TENSILEGFX90A="TensileLibrary_gfx90a.co"
    TENSILEGFX1030="TensileLibrary_gfx1030.co"
    HIPFFT_DEP=/opt/rocm/hipfft/lib/libhipfft.so
    HIPFFT_SO=libhipfft.so
elif [[ $ROCM_INT -ge 40100 ]]; then
    LIBAMDCOMGR=libamd_comgr.so.2
    SRCLIST_PATH=
    DSTLIST_PATH=
    KERNELGFX906=gfx906-xnack-
    KERNELGFX908=gfx908-xnack-
    KERNELGFX90A=
    KERNELGFX90A_=
    KERNELGFX1030=
    TENSILEGFX90A=
    TENSILEGFX1030=
    HIPFFT_DEP=/opt/rocm/hipfft/lib/libhipfft.so
    HIPFFT_SO=libhipfft.so
else
    LIBAMDCOMGR=libamd_comgr.so.1
    SRCLIST_PATH=
    DSTLIST_PATH=
    KERNELGFX906=gfx906
    KERNELGFX908=gfx908
    KERNELGFX90A=
    KERNELGFX90A_=
    KERNELGFX1030=
    TENSILEGFX90A=
    TENSILEGFX1030=
    HIPFFT_DEP=
    HIPFFT_SO=
fi;

if [[ $ROCM_INT -ge 50100 ]]; then
    HIPRAND_DEP="/opt/rocm/lib/libhiprand.so.1"
    HIPRAND_SO="libhiprand.so.1"
    ROCRAND_DEP="/opt/rocm/lib/librocrand.so.1"
    ROCRAND_SO="librocrand.so.1"
else
    HIPRAND_DEP="/opt/rocm/hiprand/lib/libhiprand.so.1"
    HIPRAND_SO="libhiprand.so.1"
    ROCRAND_DEP="/opt/rocm/rocrand/lib/librocrand.so.1"
    ROCRAND_SO="librocrand.so.1"
fi

#in rocm4.5, libhsakmt is statically linked into hsa runtime
if [[ $ROCM_INT -ge 40500 ]]; then
    HSAKMT_DEP=
    HSAKMT_SO=
else
    HSAKMT_DEP="/opt/rocm/${MAYBE_LIB64}/libhsakmt.so.1"
    HSAKMT_SO="libhsakmt.so.1"
fi

#in rocm4.5, librocm_smi64 and libroctracer64 deps added
if [[ $ROCM_INT -ge 50000 ]]; then
    ROCM_SMI_DEP=/opt/rocm/rocm_smi/lib/librocm_smi64.so.5
    ROCM_SMI_SO=librocm_smi64.so.5
elif [[ $ROCM_INT -ge 40500 ]]; then
    ROCM_SMI_DEP=/opt/rocm/rocm_smi/lib/librocm_smi64.so.4
    ROCM_SMI_SO=librocm_smi64.so.4
else
    ROCM_SMI_DEP=
    ROCM_SMI_SO=
fi

#since rocm4.5, amdgpu is an added dependency
if [[ $ROCM_INT -ge 40500 ]]; then
    DRM_IDS_SRC=/opt/amdgpu/share/libdrm/amdgpu.ids
    DRM_IDS_DST=share/libdrm/amdgpu.ids
    DRM_SO=libdrm.so.2
    DRM_AMDGPU_SO=libdrm_amdgpu.so.1
    if [[ "$OS_NAME" == *"CentOS Linux"* ]]; then
        DRM_DEP=/opt/amdgpu/lib64/${DRM_SO}
        DRM_AMDGPU_DEP=/opt/amdgpu/lib64/${DRM_AMDGPU_SO}
    elif [[ "$OS_NAME" == *"Ubuntu"* ]]; then
        DRM_DEP=/usr/lib/x86_64-linux-gnu/${DRM_SO}
        DRM_AMDGPU_DEP=/usr/lib/x86_64-linux-gnu/${DRM_AMDGPU_SO}
    fi
else
    DRM_DEP=
    DRM_SO=
    DRM_AMDGPU_DEP=
    DRM_AMDGPU_SO=
fi

# in rocm4.3, rocfft refactored their device libs, hipfft is a new package, separate from rocfft
# in rocm4.5, rocfft refactored their device libs again
if [[ $ROCM_INT -ge 40500 ]]; then
    DEP_ROCFFT_DEVICE_0=/opt/rocm/rocfft/lib/librocfft-device-0.so.0
    DEP_ROCFFT_DEVICE_1=/opt/rocm/rocfft/lib/librocfft-device-1.so.0
    DEP_ROCFFT_DEVICE_2=/opt/rocm/rocfft/lib/librocfft-device-2.so.0
    DEP_ROCFFT_DEVICE_3=/opt/rocm/rocfft/lib/librocfft-device-3.so.0
    SO_ROCFFT_DEVICE_0=librocfft-device-0.so.0
    SO_ROCFFT_DEVICE_1=librocfft-device-1.so.0
    SO_ROCFFT_DEVICE_2=librocfft-device-2.so.0
    SO_ROCFFT_DEVICE_3=librocfft-device-3.so.0
elif [[ $ROCM_INT -ge 40300 ]]; then
    DEP_ROCFFT_DEVICE_0=/opt/rocm/rocfft/lib/librocfft-device-misc.so.0
    DEP_ROCFFT_DEVICE_1=/opt/rocm/rocfft/lib/librocfft-device-single.so.0
    DEP_ROCFFT_DEVICE_2=/opt/rocm/rocfft/lib/librocfft-device-double.so.0
    DEP_ROCFFT_DEVICE_3=
    SO_ROCFFT_DEVICE_0=librocfft-device-misc.so.0
    SO_ROCFFT_DEVICE_1=librocfft-device-single.so.0
    SO_ROCFFT_DEVICE_2=librocfft-device-double.so.0
    SO_ROCFFT_DEVICE_3=
else
    DEP_ROCFFT_DEVICE_0=/opt/rocm/rocfft/lib/librocfft-device.so.0
    DEP_ROCFFT_DEVICE_1=
    DEP_ROCFFT_DEVICE_2=
    DEP_ROCFFT_DEVICE_3=
    SO_ROCFFT_DEVICE_0=librocfft-device.so.0
    SO_ROCFFT_DEVICE_1=
    SO_ROCFFT_DEVICE_2=
    SO_ROCFFT_DEVICE_3=
fi;

echo "PYTORCH_ROCM_ARCH: ${PYTORCH_ROCM_ARCH}"

DEPS_LIST=(
    "/opt/rocm/miopen/lib/libMIOpen.so.1"
    "/opt/rocm/hip/lib/$LIBAMDHIP64"
    "/opt/rocm/hipblas/lib/libhipblas.so.0"
    ${HIPFFT_DEP}
    ${HIPRAND_DEP}
    "/opt/rocm/hipsparse/lib/libhipsparse.so.0"
    "/opt/rocm/hsa/lib/libhsa-runtime64.so.1"
    "/opt/rocm/${MAYBE_LIB64}/${LIBAMDCOMGR}"
    ${HSAKMT_DEP}
    "/opt/rocm/magma/lib/libmagma.so"
    "/opt/rocm/rccl/lib/librccl.so.1"
    "/opt/rocm/rocblas/lib/librocblas.so.0"
    ${DEP_ROCFFT_DEVICE_0}
    ${DEP_ROCFFT_DEVICE_1}
    ${DEP_ROCFFT_DEVICE_2}
    ${DEP_ROCFFT_DEVICE_3}
    "/opt/rocm/rocfft/lib/librocfft.so.0"
    ${ROCM_SMI_DEP}
    ${ROCRAND_DEP}
    "/opt/rocm/rocsolver/lib/librocsolver.so.0"
    "/opt/rocm/rocsparse/lib/librocsparse.so.0"
    "/opt/rocm/roctracer/lib/libroctracer64.so.1"
    "/opt/rocm/roctracer/lib/libroctx64.so.1"
    "$LIBGOMP_PATH"
    "$LIBNUMA_PATH"
    "$LIBELF_PATH"
    "$LIBTINFO_PATH"
    ${DRM_DEP}
    ${DRM_AMDGPU_DEP}
)

DEPS_SONAME=(
    "libMIOpen.so.1"
    "$LIBAMDHIP64"
    "libhipblas.so.0"
    ${HIPFFT_SO}
    ${HIPRAND_SO}
    "libhipsparse.so.0"
    "libhsa-runtime64.so.1"
    "${LIBAMDCOMGR}"
    ${HSAKMT_SO}
    "libmagma.so"
    "librccl.so.1"
    "librocblas.so.0"
    ${SO_ROCFFT_DEVICE_0}
    ${SO_ROCFFT_DEVICE_1}
    ${SO_ROCFFT_DEVICE_2}
    ${SO_ROCFFT_DEVICE_3}
    "librocfft.so.0"
    ${ROCM_SMI_SO}
    ${ROCRAND_SO}
    "librocsolver.so.0"
    "librocsparse.so.0"
    "libroctracer64.so.1"
    "libroctx64.so.1"
    "libgomp.so.1"
    "libnuma.so.1"
    "libelf.so.1"
    "libtinfo.so.5"
    ${DRM_SO}
    ${DRM_AMDGPU_SO}
)

DEPS_AUX_SRCLIST=(
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx803.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-gfx900.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-${KERNELGFX906}.hsaco"
    "/opt/rocm/rocblas/lib/library/Kernels.so-000-${KERNELGFX908}.hsaco"
    ${SRCLIST_PATH}${KERNELGFX90A}
    ${SRCLIST_PATH}${KERNELGFX90A_}
    ${SRCLIST_PATH}${KERNELGFX1030}
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx803.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx900.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx906.co"
    "/opt/rocm/rocblas/lib/library/TensileLibrary_gfx908.co"
    ${SRCLIST_PATH}${TENSILEGFX90A}
    ${SRCLIST_PATH}${TENSILEGFX1030}
    "/opt/rocm/rocblas/lib/library/$TENSILE_LIBRARY_NAME"
    ${DRM_IDS_SRC}
)

DEPS_AUX_DSTLIST=(
    "lib/library/Kernels.so-000-gfx803.hsaco"
    "lib/library/Kernels.so-000-gfx900.hsaco"
    "lib/library/Kernels.so-000-${KERNELGFX906}.hsaco"
    "lib/library/Kernels.so-000-${KERNELGFX908}.hsaco"
    ${DSTLIST_PATH}${KERNELGFX90A}
    ${DSTLIST_PATH}${KERNELGFX90A_}
    ${DSTLIST_PATH}${KERNELGFX1030}
    "lib/library/TensileLibrary_gfx803.co"
    "lib/library/TensileLibrary_gfx900.co"
    "lib/library/TensileLibrary_gfx906.co"
    "lib/library/TensileLibrary_gfx908.co"
    ${DSTLIST_PATH}${TENSILEGFX90A}
    ${DSTLIST_PATH}${TENSILEGFX1030}
    "lib/library/$TENSILE_LIBRARY_NAME"
    ${DRM_IDS_DST}
)

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
if [[ -z "$BUILD_PYTHONLESS" ]]; then
    BUILD_SCRIPT=build_common.sh
else
    BUILD_SCRIPT=build_libtorch.sh
fi
source $SCRIPTPATH/${BUILD_SCRIPT}
