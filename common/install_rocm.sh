#!/bin/bash

set -ex

ROCM_VERSION=$1

yum update -y
yum install -y kmod
yum install -y wget
yum install -y openblas-devel

yum install -y epel-release
yum install -y dkms kernel-headers-`uname -r` kernel-devel-`uname -r`

ver() {
    printf "%3d%03d%03d%03d" $(echo "$1" | tr '.' ' ');
}

if [[ $(ver $ROCM_VERSION) -ge $(ver 4.5) ]]; then
    # Map ROCm version to AMDGPU version
    declare -A AMDGPU_VERSIONS=( ["4.5.2"]="21.40.2" )

    # Add amdgpu repository
    amdgpu_baseurl="https://repo.radeon.com/amdgpu/${AMDGPU_VERSIONS[$ROCM_VERSION]}/rhel/7.9/main/x86_64"
    echo "[AMDGPU]" > /etc/yum.repos.d/amdgpu.repo
    echo "name=AMDGPU" >> /etc/yum.repos.d/amdgpu.repo
    echo "baseurl=${amdgpu_baseurl}" >> /etc/yum.repos.d/amdgpu.repo
    echo "enabled=1" >> /etc/yum.repos.d/amdgpu.repo
    echo "gpgcheck=1" >> /etc/yum.repos.d/amdgpu.repo
    echo "gpgkey=http://repo.radeon.com/rocm/rocm.gpg.key" >> /etc/yum.repos.d/amdgpu.repo
fi

rocm_baseurl="http://repo.radeon.com/rocm/yum/${ROCM_VERSION}"
echo "[ROCm]" > /etc/yum.repos.d/rocm.repo
echo "name=ROCm" >> /etc/yum.repos.d/rocm.repo
echo "baseurl=${rocm_baseurl}" >> /etc/yum.repos.d/rocm.repo
echo "enabled=1" >> /etc/yum.repos.d/rocm.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/rocm.repo
echo "gpgkey=http://repo.radeon.com/rocm/rocm.gpg.key" >> /etc/yum.repos.d/rocm.repo

yum update -y

yum install -y \
                 rocm-dev \
                 rocm-utils \
                 rocm-libs \
                 rccl \
                 rocprofiler-dev \
                 roctracer-dev

# Cleanup
yum clean all
rm -rf /var/cache/yum
rm -rf /var/lib/yum/yumdb
rm -rf /var/lib/yum/history
