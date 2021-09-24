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

# Uninstall existing package, to avoid errors during later yum install indicating packages did not change.
yum remove -y miopen-hip

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

## MIOpen minimum requirements

### Boost; No viable yum package exists. Must use static linking with PIC.
retry wget https://boostorg.jfrog.io/artifactory/main/release/1.72.0/source/boost_1_72_0.tar.gz
tar xzf boost_1_72_0.tar.gz
pushd boost_1_72_0
./bootstrap.sh
./b2 -j $(nproc) threading=multi link=static cxxflags=-fPIC --with-system --with-filesystem install
popd
rm -rf boost_1_72_0
rm -f  boost_1_72_0.tar.gz

### sqlite; No viable yum package exists. Must be at least version 3.14.
retry wget https://sqlite.org/2017/sqlite-autoconf-3170000.tar.gz
tar xzf sqlite-autoconf-3170000.tar.gz
pushd sqlite-autoconf-3170000
./configure --with-pic
make -j $(nproc)
make install
popd
rm -rf sqlite-autoconf-3170000
rm -f  sqlite-autoconf-3170000.tar.gz

### half header
retry curl -fsSL https://raw.githubusercontent.com/ROCmSoftwarePlatform/half/master/include/half.hpp -o /usr/include/half.hpp

### bzip2
yum install -y bzip2-devel

## Build MIOpen

# MIOPEN_USE_HIP_KERNELS is a Workaround for COMgr issues
MIOPEN_CMAKE_COMMON_FLAGS="
-DMIOPEN_USE_COMGR=ON
-DMIOPEN_BUILD_DRIVER=OFF
"
if [[ ${ROCM_VERSION} == 4.1 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx803_36;gfx803_64;gfx900_56;gfx900_64;gfx906_60;gfx906_64;gfx90878"
    MIOPEN_BRANCH="rocm-4.1.x-staging"
elif [[ ${ROCM_VERSION} == 4.2 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx803_36;gfx803_64;gfx900_56;gfx900_64;gfx906_60;gfx906_64;gfx90878"
    MIOPEN_BRANCH="rocm-4.2.x-staging"
elif [[ ${ROCM_VERSION} == 4.3.1 ]]; then
    MIOPEN_CMAKE_DB_FLAGS="-DMIOPEN_EMBED_DB=gfx900_56;gfx900_64;gfx906_60;gfx906_64;gfx90878;gfx1030_36"
    MIOPEN_BRANCH="release/rocm-rel-4.3"
else
    echo "Unhandled ROCM_VERSION ${ROCM_VERSION}"
    exit 1
fi

git clone https://github.com/ROCmSoftwarePlatform/MIOpen -b ${MIOPEN_BRANCH}
pushd MIOpen
mkdir -p build
cd build
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig CXX=${ROCM_INSTALL_PATH}/llvm/bin/clang++ cmake .. \
    ${MIOPEN_CMAKE_COMMON_FLAGS} \
    ${MIOPEN_CMAKE_DB_FLAGS} \
    -DCMAKE_PREFIX_PATH="${ROCM_INSTALL_PATH}/hip;${ROCM_INSTALL_PATH}"
make MIOpen -j $(nproc)
make -j $(nproc) package
yum install -y miopen-*.rpm
popd
rm -rf MIOpen

# Cleanup
yum clean all
rm -rf /var/cache/yum
rm -rf /var/lib/yum/yumdb
rm -rf /var/lib/yum/history
