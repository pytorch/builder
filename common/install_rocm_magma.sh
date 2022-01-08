#!/bin/bash

set -ex

# "install" hipMAGMA into /opt/rocm/magma by copying after build
git clone https://bitbucket.org/icl/magma.git
pushd magma
git checkout c62d700d880c7283b33fb1d615d62fc9c7f7ca21
cp make.inc-examples/make.inc.hip-gcc-mkl make.inc
echo 'LIBDIR += -L$(MKLROOT)/lib' >> make.inc
# overwrite original LIB, because it's wrong; it's missing start/end-group
echo 'LIB = -Wl,--start-group -lmkl_gf_lp64 -lmkl_gnu_thread -lmkl_core -Wl,--end-group -lpthread -lstdc++ -lm -lgomp -lhipblas -lhipsparse' >> make.inc
echo 'LIB += -Wl,--enable-new-dtags -Wl,--rpath,/opt/rocm/lib -Wl,--rpath,$(MKLROOT)/lib -Wl,--rpath,/opt/rocm/magma/lib, -ldl' >> make.inc
export PATH="${PATH}:/opt/rocm/bin"
echo 'DEVCCFLAGS += --gpu-max-threads-per-block=256' >> make.inc
if [[ -n "$PYTORCH_ROCM_ARCH" ]]; then
  amdgpu_targets=`echo $PYTORCH_ROCM_ARCH | sed 's/;/ /g'`
else
  echo "PYTORCH_ROCM_ARCH env var is NOT set. Aborting"
  exit 1
fi
for arch in $amdgpu_targets; do
  echo "DEVCCFLAGS += --amdgpu-target=$arch" >> make.inc
done

# hipcc with openmp flag causes isnan() on __device__ not to be found; depending on context, compiler may attempt to match with host definition
sed -i 's/^FOPENMP/#FOPENMP/g' make.inc
make -f make.gen.hipMAGMA -j $(nproc)
LANG=C.UTF-8 make lib/libmagma.so -j $(nproc) MKLROOT=/opt/intel
make testing/testing_dgemm -j $(nproc) MKLROOT=/opt/intel
popd
mv magma /opt/rocm

