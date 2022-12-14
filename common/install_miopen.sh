#!/bin/bash

set -ex

ROCM_VERSION=$1

if [[ -z $ROCM_VERSION ]]; then
    echo "missing ROCM_VERSION"
    exit 1;
fi

# To make version comparison easier, create an integer representation.
save_IFS="$IFS"
IFS=. ROCM_VERSION_ARRAY=(${ROCM_VERSION})
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

# Install custom MIOpen + COMgr for ROCm >= 4.0.1
if [[ $ROCM_INT -lt 40001 ]]; then
    echo "ROCm version < 4.0.1; will not install custom MIOpen"
    exit 0
fi

# CHANGED: Do not uninstall. To avoid out of disk space issues, we will copy lib over existing.
# Uninstall existing package, to avoid errors during later yum install indicating packages did not change.
#yum remove -y miopen-hip

# Function to retry functions that sometimes timeout or have flaky failures
retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

# Build custom MIOpen to use comgr for offline compilation.

## Need a sanitized ROCM_VERSION without patchlevel; patchlevel version 0 must be added to paths.
ROCM_DOTS=$(echo ${ROCM_VERSION} | tr -d -c '.' | wc -c)
if [[ ${ROCM_DOTS} == 1 ]]; then
    ROCM_VERSION_NOPATCH="${ROCM_VERSION}"
    ROCM_INSTALL_PATH="/opt/rocm-${ROCM_VERSION}.0"
else
    ROCM_VERSION_NOPATCH="${ROCM_VERSION%.*}"
    ROCM_INSTALL_PATH="/opt/rocm-${ROCM_VERSION}"
fi

# MIOPEN_USE_HIP_KERNELS is a Workaround for COMgr issues
MIOPEN_CMAKE_COMMON_FLAGS="
-DMIOPEN_USE_COMGR=ON
-DMIOPEN_BUILD_DRIVER=OFF
"
# Pull MIOpen repo and set DMIOPEN_EMBED_DB based on ROCm version
if [[ $ROCM_INT -ge 50400 ]] && [[ $ROCM_INT -lt 50500 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx900_56;gfx906_60;gfx90878;gfx90a6e;gfx1030_36 -DMIOPEN_USE_MLIR=Off"
    MIOPEN_BRANCH="release/rocm-rel-5.4-staging"
else if [[ $ROCM_INT -ge 50300 ]] && [[ $ROCM_INT -lt 50400 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx900_56;gfx906_60;gfx90878;gfx90a6e;gfx1030_36 -DMIOPEN_USE_MLIR=Off"
    MIOPEN_BRANCH="release/rocm-rel-5.3-staging"
elif [[ $ROCM_INT -ge 50200 ]] && [[ $ROCM_INT -lt 50300 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx900_56;gfx906_60;gfx90878;gfx90a6e;gfx1030_36 -DMIOPEN_USE_MLIR=Off"
    MIOPEN_BRANCH="release/rocm-rel-5.2-staging"
elif [[ $ROCM_INT -ge 50100 ]] && [[ $ROCM_INT -lt 50200 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx900_56;gfx906_60;gfx90878;gfx90a6e;gfx1030_36"
    MIOPEN_BRANCH="release/rocm-rel-5.1-staging"
elif [[ $ROCM_INT -ge 50000 ]] && [[ $ROCM_INT -lt 50100 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx900_56;gfx906_60;gfx90878;gfx90a6e;gfx1030_36"
    MIOPEN_BRANCH="release/rocm-rel-5.0-staging"
elif [[ $ROCM_INT -ge 40500 ]] && [[ $ROCM_INT -lt 50000 ]]; then
    MIOPEN_CMAKE_COMMON_FLAGS="${MIOPEN_CMAKE_COMMON_FLAGS} -DMIOPEN_USE_HIP_KERNELS=Off -DMIOPEN_DEFAULT_FIND_MODE=Normal"
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx900_56;gfx906_60;gfx90878;gfx90a6e;gfx1030_36"
    MIOPEN_BRANCH="release/rocm-rel-4.5-staging"
elif [[ $ROCM_INT -ge 40300 ]] && [[ $ROCM_INT -lt 40500 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx900_56;gfx900_64;gfx906_60;gfx906_64;gfx90878;gfx1030_36"
    MIOPEN_BRANCH="release/rocm-rel-4.3-staging"
elif [[ $ROCM_INT -ge 40200 ]] && [[ $ROCM_INT -lt 40300 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx803_36;gfx803_64;gfx900_56;gfx900_64;gfx906_60;gfx906_64;gfx90878"
    MIOPEN_BRANCH="rocm-4.2.x-staging"
else
    echo "Unhandled ROCM_VERSION ${ROCM_VERSION}"
    exit 1
fi

git clone https://github.com/ROCmSoftwarePlatform/MIOpen -b ${MIOPEN_BRANCH}
pushd MIOpen
# remove .git to save disk space ince CI runner was running out
rm -rf .git
# Don't build MLIR to save docker build time
# since we are disabling MLIR backend for MIOpen anyway
if [[ $ROCM_INT -ge 50400 ]] && [[ $ROCM_INT -lt 50500 ]]; then
    sed -i '/rocMLIR/d' requirements.txt
elif [[ $ROCM_INT -ge 50200 ]] && [[ $ROCM_INT -lt 50400 ]]; then
    sed -i '/llvm-project-mlir/d' requirements.txt
fi
## MIOpen minimum requirements
cmake -P install_deps.cmake --minimum

# clean up since CI runner was running out of disk space
rm -rf /tmp/*
yum clean all
rm -rf /var/cache/yum
rm -rf /var/lib/yum/yumdb
rm -rf /var/lib/yum/history

## Build MIOpen
mkdir -p build
cd build
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig CXX=${ROCM_INSTALL_PATH}/llvm/bin/clang++ cmake .. \
    ${MIOPEN_CMAKE_COMMON_FLAGS} \
    ${MIOPEN_CMAKE_DB_FLAGS} \
    -DCMAKE_PREFIX_PATH="${ROCM_INSTALL_PATH}/hip;${ROCM_INSTALL_PATH}"
make MIOpen -j $(nproc)

# CHANGED: Do not build package.
# Build MIOpen package
#make -j $(nproc) package

# clean up since CI runner was running out of disk space
rm -rf /usr/local/cget

# CHANGED: Do not install package, just copy lib over existing.
#yum install -y miopen-*.rpm
dest=$(ls ${ROCM_INSTALL_PATH}/lib/libMIOpen.so.1.0.*)
rm -f ${dest}
cp lib/libMIOpen.so.1.0 ${dest}

popd
rm -rf MIOpen
