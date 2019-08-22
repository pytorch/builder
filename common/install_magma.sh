# Install MAGMA for CUDA 9.2
pushd /tmp
wget -q https://anaconda.org/pytorch/magma-cuda92/2.5.1/download/linux-64/magma-cuda92-2.5.1-1.tar.bz2
tar -xvf magma-cuda92-2.5.1-1.tar.bz2
mkdir -p /usr/local/cuda-9.2/magma
mv include /usr/local/cuda-9.2/magma/include
mv lib /usr/local/cuda-9.2/magma/lib
rm -rf info lib include magma-cuda92-2.5.1-1.tar.bz2

# Install MAGMA for CUDA 10.0
pushd /tmp
wget -q https://anaconda.org/pytorch/magma-cuda100/2.5.1/download/linux-64/magma-cuda100-2.5.1-1.tar.bz2
tar -xvf magma-cuda100-2.5.1-1.tar.bz2
mkdir -p /usr/local/cuda-10.0/magma
mv include /usr/local/cuda-10.0/magma/include
mv lib /usr/local/cuda-10.0/magma/lib
rm -rf info lib include magma-cuda100-2.5.1-1.tar.bz2
