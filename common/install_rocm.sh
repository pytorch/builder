#!/bin/bash

set -ex

ROCM_VERSION=$1

yum update -y
yum install -y kmod
yum install -y wget
yum install -y openblas-devel

yum install -y epel-release
yum install -y dkms kernel-headers-`uname -r` kernel-devel-`uname -r`

echo "[ROCm]" > /etc/yum.repos.d/rocm.repo
echo "name=ROCm" >> /etc/yum.repos.d/rocm.repo
echo "baseurl=http://repo.radeon.com/rocm/yum/${ROCM_VERSION}" >> /etc/yum.repos.d/rocm.repo
echo "enabled=1" >> /etc/yum.repos.d/rocm.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/rocm.repo

yum update -y

yum install -y \
                 rocm-dev \
                 rocm-utils \
                 rocfft \
                 miopen-hip \
                 rocblas \
                 hipsparse \
                 rocrand \
                 rccl \
                 hipcub \
                 rocthrust \
                 rocprofiler-dev \
                 roctracer-dev

# Cleanup
yum clean all
rm -rf /var/cache/yum
rm -rf /var/lib/yum/yumdb
rm -rf /var/lib/yum/history
