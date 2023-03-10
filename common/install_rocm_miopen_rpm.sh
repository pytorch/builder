#!/bin/bash

set -ex

# Create the tmp dir to extract into
EXTRACTDIR_ROOT=/extract_miopen_rpm
mkdir -p ${EXTRACTDIR_ROOT}
echo "Creating temporary directory for rpm download..."

# Fail if rpm source is not available
if ! wget -P ${EXTRACTDIR_ROOT} ${MIOPEN_RPM_SOURCE}; then
  echo 'ERROR: Failed to download MIOpen package.'
  exit 1
fi
echo "MIOpen package download complete..."

# Extract rpm in EXTRACT_DIR
cd ${EXTRACTDIR_ROOT}
miopen_rpm=$(ls *.rpm)
rpm2cpio ${miopen_rpm} | cpio -idmv 

# Copy libMIOpen.so.1 over existing
source_file=$(ls opt/rocm-*/lib/libMIOpen.so.1.0*)
dest_file=$(ls /opt/rocm-${ROCM_VERSION}*/lib/libMIOpen.so.1.0*)
if [ -e ${source_file} ] && [ -e ${dest_file} ]; then
  echo "Source .so: ${source_file}"
  echo "Dest .so: ${dest_file}"
  cp $source_file $dest_file
else
  echo 'ERROR: either the source or destination path for libMIOpen.so.1.0 does not exist'
  exit 1
fi
echo "libMIOpen so file from RPM copied to existing MIOpen install..."

# Clean up extracted dir
rm -rf ${EXTRACTDIR_ROOT}
echo "Removed temporary directory..."
