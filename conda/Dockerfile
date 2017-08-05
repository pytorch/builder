FROM nvidia/cuda:8.0-devel-centos6

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN yum install -y wget curl perl cmake util-linux

ENV CUDNN_VERSION 6.0.21

RUN CUDNN_DOWNLOAD_SUM=9b09110af48c9a4d7b6344eb4b3e344daa84987ed6177d5c44319732f3bb7f9c && \
    curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-8.0-linux-x64-v6.0.tgz -O && \
    echo "$CUDNN_DOWNLOAD_SUM  cudnn-8.0-linux-x64-v6.0.tgz" | sha256sum -c - && \
    tar -xzf cudnn-8.0-linux-x64-v6.0.tgz -C /usr/local && \
    rm cudnn-8.0-linux-x64-v6.0.tgz && \
    ldconfig

RUN wget https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/cuda_8.0.61.2_linux-run && \
    chmod +x cuda_8.0.61.2_linux-run && \
    cp /usr/local/cuda/version.txt /tmp/ && \
    ./cuda_8.0.61.2_linux-run --silent --accept-eula --installdir=/tmp && \
    yes | cp -P /tmp/lib64/* /usr/local/cuda/lib64/ && \
    rm -rf /usr/local/cuda/lib64/lib*blas.so.8.0.61

# install CUDA 7.5 in the same container
RUN wget http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run && \
    chmod +x cuda_7.5.18_linux.run && \
    ./cuda_7.5.18_linux.run --silent --no-opengl-libs --toolkit && \
    rm -f cuda_7.5.18_linux.run

# install CUDA 7.5 cudnn
RUN CUDNN_DOWNLOAD_SUM=568d4b070c5f91ab8a15b287b73dd072b99c7267a43edad13f70337cd186c82c && \
    curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-7.5-linux-x64-v6.0.tgz -O && \
    echo "$CUDNN_DOWNLOAD_SUM  cudnn-7.5-linux-x64-v6.0.tgz" | sha256sum -c - && \
    tar -xzf cudnn-7.5-linux-x64-v6.0.tgz -C /usr/local && \
    rm -f cudnn-7.5-linux-x64-v6.0.tgz && \
    ldconfig


# Anaconda
RUN wget https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh && \
    chmod +x Miniconda2-latest-Linux-x86_64.sh && \
    ./Miniconda2-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda2-latest-Linux-x86_64.sh
ENV PATH /opt/conda/bin:$PATH
RUN conda install -y conda-build anaconda-client git