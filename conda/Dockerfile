FROM nvidia/cuda:8.0-devel-centos7

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN yum install -y wget curl perl cmake util-linux xz bzip2 git patch which
RUN yum install -y yum-utils centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-gcc-gfortran devtoolset-3-binutils
ENV PATH=/opt/rh/devtoolset-3/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-3/root/usr/lib64:/opt/rh/devtoolset-3/root/usr/lib:$LD_LIBRARY_PATH

RUN yum install -y autoconf aclocal automake make
RUN git clone https://github.com/NixOS/patchelf && \
    cd patchelf && \
    sed -i 's/serial/parallel/g' configure.ac && \
    ./bootstrap.sh && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf patchelf


RUN wget -q https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/cuda_8.0.61.2_linux-run && \
    chmod +x cuda_8.0.61.2_linux-run && \
    cp /usr/local/cuda/version.txt /tmp/ && \
    ./cuda_8.0.61.2_linux-run --silent --accept-eula --installdir=/tmp && \
    yes | cp -P /tmp/lib64/* /usr/local/cuda/lib64/ && \
    rm -rf /usr/local/cuda/lib64/lib*blas.so.8.0.61 && \
    rm -r cuda_8.0.61.2_linux-run

# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
RUN curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v7.1.2/cudnn-8.0-linux-x64-v7.1.tgz -O && \
    tar --no-same-owner -xzf cudnn-8.0-linux-x64-v7.1.tgz -C /usr/local && \
    rm cudnn-8.0-linux-x64-v7.1.tgz && \
    ldconfig

# NCCL2
RUN wget -q https://s3.amazonaws.com/pytorch/nccl_2.1.15-1%2Bcuda8.0_x86_64.txz && \
    ls && \
    ls -alh nccl_2.1.15-1+cuda8.0_x86_64.txz && \
    tar --no-same-owner -xvf nccl_2.1.15-1+cuda8.0_x86_64.txz && \
    mv nccl_2.1.15-1+cuda8.0_x86_64/include/* /usr/local/cuda/include/ && \
    cp -P nccl_2.1.15-1+cuda8.0_x86_64/lib/libnccl* /usr/local/cuda/lib64/ && \
    rm -rf nccl_2.1.15-1+cuda8.0_x86_64* && \
    ldconfig

# install CUDA 9.0 in the same container
RUN wget -q https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_384.81_linux-run && \
    chmod +x cuda_9.0.176_384.81_linux-run && \
    ./cuda_9.0.176_384.81_linux-run --silent --no-opengl-libs --toolkit && \
    rm -f cuda_9.0.176_384.81_linux-run

# patch 1, patch2
RUN wget -q https://developer.nvidia.com/compute/cuda/9.0/Prod/patches/1/cuda_9.0.176.1_linux-run && \
    chmod +x cuda_9.0.176.1_linux-run && \
    ./cuda_9.0.176.1_linux-run -s --accept-eula && \
    rm -f cuda_9.0.176.1_linux-run
RUN wget -q https://developer.nvidia.com/compute/cuda/9.0/Prod/patches/2/cuda_9.0.176.2_linux-run && \
    chmod +x cuda_9.0.176.2_linux-run && \
    ./cuda_9.0.176.2_linux-run -s --accept-eula && \
    rm -f cuda_9.0.176.2_linux-run

# install CUDA 9.0 CuDNN
# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
RUN curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v7.1.2/cudnn-9.0-linux-x64-v7.1.tgz -O && \
    tar --no-same-owner -xzf cudnn-9.0-linux-x64-v7.1.tgz -C /usr/local && \
    rm cudnn-9.0-linux-x64-v7.1.tgz && \
    ldconfig

# NCCL2
RUN wget -q https://s3.amazonaws.com/pytorch/nccl_2.1.15-1%2Bcuda9.0_x86_64.txz && \
    tar --no-same-owner -xvf nccl_2.1.15-1+cuda9.0_x86_64.txz && \
    mv nccl_2.1.15-1+cuda9.0_x86_64/include/* /usr/local/cuda/include/ && \
    cp -P nccl_2.1.15-1+cuda9.0_x86_64/lib/libnccl* /usr/local/cuda/lib64/ && \
    rm -rf nccl_2.1.15-1+cuda9.0_x86_64* && \
    ldconfig

# install CUDA 9.1 in the same container
RUN wget -q https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_387.26_linux && \
    chmod +x cuda_9.1.85_387.26_linux && \
    ./cuda_9.1.85_387.26_linux --silent --no-opengl-libs --toolkit && \
    rm -f cuda_9.1.85_387.26_linux

# patch 1, patch2, patch3
RUN wget -q https://developer.nvidia.com/compute/cuda/9.1/Prod/patches/1/cuda_9.1.85.1_linux && \
    chmod +x cuda_9.1.85.1_linux && \
    ./cuda_9.1.85.1_linux -s --accept-eula && \
    rm -f cuda_9.1.85.1_linux
RUN wget -q https://developer.nvidia.com/compute/cuda/9.1/Prod/patches/2/cuda_9.1.85.2_linux && \
    chmod +x cuda_9.1.85.2_linux && \
    ./cuda_9.1.85.2_linux -s --accept-eula && \
    rm -f cuda_9.1.85.2_linux
RUN wget -q https://developer.nvidia.com/compute/cuda/9.1/Prod/patches/3/cuda_9.1.85.3_linux && \
    chmod +x cuda_9.1.85.3_linux && \
    ./cuda_9.1.85.3_linux -s --accept-eula && \
    rm -f cuda_9.1.85.3_linux


# install CUDA 9.1 CuDNN
# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
RUN curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v7.1.2/cudnn-9.1-linux-x64-v7.1.tgz -O && \
    tar --no-same-owner -xzf cudnn-9.1-linux-x64-v7.1.tgz -C /usr/local && \
    rm cudnn-9.1-linux-x64-v7.1.tgz && \
    ldconfig

# NCCL2
RUN wget -q https://s3.amazonaws.com/pytorch/nccl_2.1.15-1%2Bcuda9.1_x86_64.txz && \
    tar --no-same-owner -xvf nccl_2.1.15-1+cuda9.1_x86_64.txz && \
    mv nccl_2.1.15-1+cuda9.1_x86_64/include/* /usr/local/cuda/include/ && \
    cp -P nccl_2.1.15-1+cuda9.1_x86_64/lib/libnccl* /usr/local/cuda/lib64/ && \
    rm -rf nccl_2.1.15-1+cuda9.1_x86_64* && \
    ldconfig

# Anaconda
RUN wget -q https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh && \
    chmod +x Miniconda2-latest-Linux-x86_64.sh && \
    ./Miniconda2-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda2-latest-Linux-x86_64.sh
ENV PATH /opt/conda/bin:$PATH
RUN conda install -y conda-build anaconda-client git ninja
RUN conda remove -y --force patchelf