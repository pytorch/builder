#!/usr/bin/env bash
set -e

yum install -y wget git cmake

# make sure CUDA 7.5 and 8.0 are installed
if ! ls /usr/local/cuda-7.5
then
    echo "Downloading CUDA 7.5"
    wget -c http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run \
	 -O /remote/cuda_7.5.18_linux.run

    echo "Installing CUDA 7.5"
    chmod +x /remote/cuda_7.5.18_linux.run
    bash remote/cuda_7.5.18_linux.run --silent --toolkit --no-opengl-libs

    echo "\nDone installing CUDA 7.5"
else
    echo "CUDA 7.5 already installed"
fi

if ! ls /usr/local/cuda-8.0
then
    echo "Downloading CUDA 8.0"
    wget -c https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run \
	 -O /remote/cuda_8.0.61_linux-run

    echo "Installing CUDA 8.0"
    chmod +x /remote/cuda_8.0.61_linux-run
    bash /remote/cuda_8.0.61_linux-run --silent --toolkit --no-opengl-libs

    echo "\nDone installing CUDA 8.0"
else
    echo "CUDA 8.0 already installed"
fi

# make sure cudnn is installed
if ! ls /usr/local/cuda-7.5/lib64/libcudnn.so.6.0.21
then
    rm -rf /tmp/cuda
    wget -c http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-7.5-linux-x64-v6.0.tgz \
	 -O /remote/cudnn-7.5-linux-x64-v6.0.tgz
    pushd /tmp
    tar -xvf /remote/cudnn-7.5-linux-x64-v6.0.tgz
    cp -P /tmp/cuda/include/* /usr/local/cuda-7.5/include/
    cp -P /tmp/cuda/lib64/* /usr/local/cuda-7.5/lib64/
    popd
fi

if ! ls /usr/local/cuda-8.0/lib64/libcudnn.so.6.0.21
then
    rm -rf /tmp/cuda
    wget -c http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-8.0-linux-x64-v6.0.tgz \
	 -O /remote/cudnn-8.0-linux-x64-v6.0.tgz
    pushd /tmp
    tar -xvf /remote/cudnn-8.0-linux-x64-v6.0.tgz
    cp -P /tmp/cuda/include/* /usr/local/cuda-8.0/include/
    cp -P /tmp/cuda/lib64/* /usr/local/cuda-8.0/lib64/
    popd
fi

# Install Anaconda
if ! ls /py
then
    echo "Miniconda needs to be installed"
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
    bash ~/miniconda.sh -b -p /py
else
    echo "Miniconda is already installed"
fi

export PATH="/py/bin:$PATH"

# Anaconda token
if ls /remote/token
then
   source /remote/token
fi

conda install -y conda-build anaconda-client
yes | pip install awscli

unset CUDA_VERSION # set in docker image :-/

# build conda packages
rm -rf /b
git clone https://github.com/pytorch/builder /b
cd /b/conda
./build_all.sh
