FROM nvidia/cuda:9.2-devel-ubuntu16.04

RUN apt-get clean && apt-get update
RUN apt-get install -y locales git-all autoconf automake make wget unzip

RUN locale-gen en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Install patchelf
ADD ./common/install_patchelf.sh install_patchelf.sh
RUN bash ./install_patchelf.sh && rm install_patchelf.sh

# Install MKL
ADD ./common/install_mkl.sh install_mkl.sh
RUN bash ./install_mkl.sh && rm install_mkl.sh

# Install CUDA
ADD ./common/install_cuda.sh install_cuda.sh
RUN bash ./install_cuda.sh && rm install_cuda.sh

# Install Anaconda
ENV PATH /opt/conda/bin:$PATH
ADD ./common/install_conda.sh install_conda.sh
RUN bash ./install_conda.sh && rm install_conda.sh
