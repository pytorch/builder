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
                 rocm-libs \
                 rccl \
                 rocprofiler-dev \
                 roctracer-dev

# "install" hipMAGMA into /opt/rocm/magma by copying after build
git clone https://bitbucket.org/icl/magma.git -b hipMAGMA
pushd magma
cp make.inc-examples/make.inc.hip-mkl-gcc make.inc
echo 'LIBDIR += -L$(MKLROOT)/lib' >> make.inc
# overwrite original LIB, because it's wrong; it's missing start/end-group
echo 'LIB = -Wl,--start-group -lmkl_gf_lp64 -lmkl_gnu_thread -lmkl_core -Wl,--end-group -lpthread -lstdc++ -lm -lgomp' >> make.inc
echo 'LIB += -Wl,--enable-new-dtags -Wl,--rpath,/opt/rocm/lib -Wl,--rpath,$(MKLROOT)/lib -Wl,--rpath,/opt/rocm/magma/lib' >> make.inc
echo 'DEVCCFLAGS += --amdgpu-target=gfx803 --amdgpu-target=gfx900 --amdgpu-target=gfx906 --amdgpu-target=gfx908' >> make.inc
export PATH="${PATH}:/opt/rocm/bin"
make -f make.gen.hipMAGMA -j $(nproc)
make lib/libmagma.so -j $(nproc) MKLROOT=/opt/intel
make testing/testing_dgemm -j $(nproc) MKLROOT=/opt/intel
popd
mv magma /opt/rocm

# Cleanup
yum clean all
rm -rf /var/cache/yum
rm -rf /var/lib/yum/yumdb
rm -rf /var/lib/yum/history
