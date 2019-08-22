# Install MAGMA for CUDA 9.2
pushd /tmp
wget -q https://anaconda.org/pytorch/magma-cuda92/2.5.1/download/linux-64/magma-cuda92-2.5.1-1.tar.bz2
tar -xvf magma-cuda92-2.5.1-1.tar.bz2
cp -r include/* /usr/local/cuda-9.2/include/
cp -r lib/* /usr/local/cuda-9.2/lib64/
rm -rf info lib include magma-cuda92-2.5.1-1.tar.bz2

# Install MAGMA for CUDA 10.0
pushd /tmp
wget -q https://anaconda.org/pytorch/magma-cuda100/2.5.1/download/linux-64/magma-cuda100-2.5.1-1.tar.bz2
tar -xvf magma-cuda100-2.5.1-1.tar.bz2
cp -r include/* /usr/local/cuda-10.0/include/
cp -r lib/* /usr/local/cuda-10.0/lib64/
rm -rf info lib include magma-cuda100-2.5.1-1.tar.bz2
