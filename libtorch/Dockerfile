ARG BASE_TARGET=base
ARG GPU_IMAGE=nvidia/cuda:10.2-devel-ubuntu18.04
FROM ${GPU_IMAGE} as base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get clean && apt-get update
RUN apt-get install -y curl locales git-all autoconf automake make cmake wget unzip

RUN locale-gen en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Install openssl
FROM base as openssl
ADD ./common/install_openssl.sh install_openssl.sh
RUN bash ./install_openssl.sh && rm install_openssl.sh

# Install python
FROM base as python
ADD common/install_cpython.sh install_cpython.sh
RUN apt-get update -y && \
    apt-get install build-essential gdb lcov libbz2-dev libffi-dev \
        libgdbm-dev liblzma-dev libncurses5-dev libreadline6-dev \
        libsqlite3-dev libssl-dev lzma lzma-dev tk-dev uuid-dev zlib1g-dev -y && \
    bash ./install_cpython.sh && \
    rm install_cpython.sh && \
    apt-get clean

FROM base as cpu
# Install MKL
ADD ./common/install_mkl.sh install_mkl.sh
RUN bash ./install_mkl.sh && rm install_mkl.sh

FROM cpu as cuda
ADD ./common/install_cuda.sh install_cuda.sh
ADD ./common/install_magma.sh install_magma.sh
ENV CUDA_HOME /usr/local/cuda

FROM base as conda
ADD ./common/install_conda.sh install_conda.sh
RUN bash ./install_conda.sh && rm install_conda.sh
RUN /opt/conda/bin/conda install -y cmake=3.18

FROM cuda as cuda11.6
RUN bash ./install_cuda.sh 11.6
RUN bash ./install_magma.sh 11.6

FROM cuda as cuda11.7
RUN bash ./install_cuda.sh 11.7
RUN bash ./install_magma.sh 11.7

FROM cuda as cuda11.8
RUN bash ./install_cuda.sh 11.8
RUN bash ./install_magma.sh 11.8

FROM cpu as rocm
ARG PYTORCH_ROCM_ARCH
ENV PYTORCH_ROCM_ARCH ${PYTORCH_ROCM_ARCH}
ENV MKLROOT /opt/intel
ADD ./common/install_rocm.sh install_rocm.sh
ADD ./common/install_rocm_drm.sh install_rocm_drm.sh
ADD ./common/install_rocm_magma.sh install_rocm_magma.sh
# gfortran and python needed for building magma from source for ROCm
RUN apt-get update -y && \
    apt-get install gfortran -y && \
    apt-get install python -y && \
    apt-get clean

FROM rocm as rocm5.4.2
RUN ROCM_VERSION=5.4.2 bash ./install_rocm.sh && rm install_rocm.sh
RUN bash ./install_rocm_drm.sh && rm install_rocm_drm.sh
RUN bash ./install_rocm_magma.sh && rm install_rocm_magma.sh

FROM rocm as rocm5.3
RUN ROCM_VERSION=5.3 bash ./install_rocm.sh && rm install_rocm.sh
RUN bash ./install_rocm_drm.sh && rm install_rocm_drm.sh
RUN bash ./install_rocm_magma.sh && rm install_rocm_magma.sh

FROM rocm as rocm5.2
RUN ROCM_VERSION=5.2 bash ./install_rocm.sh && rm install_rocm.sh
RUN bash ./install_rocm_drm.sh && rm install_rocm_drm.sh
RUN bash ./install_rocm_magma.sh && rm install_rocm_magma.sh

FROM rocm as rocm5.1.3
RUN ROCM_VERSION=5.1.3 bash ./install_rocm.sh && rm install_rocm.sh
RUN bash ./install_rocm_drm.sh && rm install_rocm_drm.sh
RUN bash ./install_rocm_magma.sh && rm install_rocm_magma.sh

FROM rocm as rocm5.1.1
RUN ROCM_VERSION=5.1.1 bash ./install_rocm.sh && rm install_rocm.sh

FROM rocm as rocm5.1
RUN ROCM_VERSION=5.1 bash ./install_rocm.sh && rm install_rocm.sh


FROM ${BASE_TARGET} as final
# Install LLVM
COPY --from=pytorch/llvm:9.0.1 /opt/llvm              /opt/llvm
COPY --from=pytorch/llvm:9.0.1 /opt/llvm_no_cxx11_abi /opt/llvm_no_cxx11_abi
COPY --from=openssl            /opt/openssl           /opt/openssl
# Install patchelf
ADD ./common/install_patchelf.sh install_patchelf.sh
RUN bash ./install_patchelf.sh && rm install_patchelf.sh
# Install Anaconda
COPY --from=conda /opt/conda /opt/conda
# Install python
COPY --from=python /opt/python    /opt/python
COPY --from=python /opt/_internal /opt/_internal
ENV PATH /opt/conda/bin:$PATH
