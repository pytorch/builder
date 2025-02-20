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

# Function to retry functions that sometimes timeout or have flaky failures
retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

# Build custom MIOpen to use comgr for offline compilation.

# Create /opt/rocm link if it doesn't exist
ln -sf /opt/rocm-${ROCM_VERSION}* /opt/rocm
ROCM_INSTALL_PATH="/opt/rocm"

# MIOPEN_USE_HIP_KERNELS is a Workaround for COMgr issues
MIOPEN_CMAKE_COMMON_FLAGS="
-DMIOPEN_USE_COMGR=ON
-DMIOPEN_BUILD_DRIVER=OFF
"
if [[ $ROCM_INT -ge 60200 ]] && [[ $ROCM_INT -lt 60204 ]]; then
    MIOPEN_BRANCH="release/rocm-rel-6.2-staging"
else
    echo "ROCm ${ROCM_VERSION} does not need any patches, do not build from source"
    exit 0
fi

# Workaround since almalinux manylinux image already has this and cget doesn't like that
rm -rf /usr/local/lib/pkgconfig/sqlite3.pc

# Versioned package name needs regex match
# Use --noautoremove to prevent other rocm packages from being uninstalled
yum remove -y miopen-hip* --noautoremove

git clone https://github.com/ROCm/MIOpen -b ${MIOPEN_BRANCH}
pushd MIOpen
git log -n1
# remove .git to save disk space since CI runner was running out
rm -rf .git
## MIOpen minimum requirements; don't rebuild CK as it's already installed with ROCm
sed -i '/composable_kernel/d' requirements.txt
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
    -DCMAKE_PREFIX_PATH="${ROCM_INSTALL_PATH}"
make MIOpen -j $(nproc)

# Build MIOpen package
make -j $(nproc) package

# clean up since CI runner was running out of disk space
rm -rf /usr/local/cget

yum install -y miopen-*.rpm

popd
rm -rf MIOpen
