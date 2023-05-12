#!/bin/bash

set -ex

# Create the tmp dir to extract into
EXTRACTDIR_ROOT=/extract_miopen_rpms
mkdir -p ${EXTRACTDIR_ROOT}
echo "Creating temporary directory for rpm download..."

MIOPEN_RPM_SOURCE_ARRAY=($MIOPEN_RPM_SOURCE)
# Fail if rpm source is not available
#if [[ ! wget -P ${EXTRACTDIR_ROOT} ${MIOPEN_RPM_SOURCE_ARRAY[0]} ]] || [[ ! wget -P ${EXTRACTDIR_ROOT} ${MIOPEN_RPM_SOURCE_ARRAY[1]} ]]; then
if ! wget -P ${EXTRACTDIR_ROOT} ${MIOPEN_RPM_SOURCE_ARRAY[0]} || ! wget -P ${EXTRACTDIR_ROOT} ${MIOPEN_RPM_SOURCE_ARRAY[1]}; then
  echo 'ERROR: Failed to download MIOpen package.'
  exit 1
fi
echo "MIOpen package download complete..."

# Extract rpm in EXTRACT_DIR
cd ${EXTRACTDIR_ROOT}
miopen_rpms=$(ls *.rpm)
for miopen_rpm in ${miopen_rpms}; do
  rpm2cpio ${miopen_rpm} | cpio -idmv
done

# Copy libMIOpen.so, headers and db files over existing
files="lib/ include/ share/miopen/db/"
for file in $files; do
  source="opt/rocm*/${file}/*"
  dest="/opt/rocm/${file}"
  # Use backslash to run cp in (non-aliased) non-interactive mode
  \cp -dR $source $dest
done
echo "libMIOpen so file from RPM copied to existing MIOpen install..."

# Clean up extracted dir
rm -rf ${EXTRACTDIR_ROOT}
echo "Removed temporary directory..."
