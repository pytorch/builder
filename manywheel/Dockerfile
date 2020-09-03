# syntax = docker/dockerfile:experimental
ARG ROCM_VERSION=3.7
ARG BASE_CUDA_VERSION=10.1
ARG GPU_IMAGE=nvidia/cuda:${BASE_CUDA_VERSION}-devel-centos7
FROM centos:7 as base

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN yum install -y wget curl perl util-linux xz bzip2 git patch which perl
RUN yum install -y yum-utils centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran devtoolset-7-binutils
ENV PATH=/opt/rh/devtoolset-7/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:$LD_LIBRARY_PATH

RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm -ivh epel-release-latest-7.noarch.rpm && \
    rm -f epel-release-latest-7.noarch.rpm

# cmake
RUN yum install -y cmake3 && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

RUN yum install -y autoconf aclocal automake make

FROM base as python
# build python
COPY manywheel/build_scripts /build_scripts
RUN bash build_scripts/build.sh && rm -r build_scripts

# remove unncessary python versions
RUN rm -rf /opt/python/cp26-cp26m /opt/_internal/cpython-2.6.9-ucs2
RUN rm -rf /opt/python/cp26-cp26mu /opt/_internal/cpython-2.6.9-ucs4
RUN rm -rf /opt/python/cp33-cp33m /opt/_internal/cpython-3.3.6
RUN rm -rf /opt/python/cp34-cp34m /opt/_internal/cpython-3.4.6

FROM base as cuda
ARG BASE_CUDA_VERSION=10.1
# Install CUDA
ADD ./common/install_cuda.sh install_cuda.sh
RUN bash ./install_cuda.sh ${BASE_CUDA_VERSION} && rm install_cuda.sh

FROM base as intel
# MKL
ADD ./common/install_mkl.sh install_mkl.sh
RUN bash ./install_mkl.sh && rm install_mkl.sh

# EPEL for cmake
FROM base as patchelf
# Install patchelf
ADD ./common/install_patchelf.sh install_patchelf.sh
RUN bash ./install_patchelf.sh && rm install_patchelf.sh
RUN cp $(which patchelf) /patchelf

FROM base as magma
ARG BASE_CUDA_VERSION=10.1
# Install magma
ADD ./common/install_magma.sh install_magma.sh
RUN bash ./install_magma.sh ${BASE_CUDA_VERSION} && rm install_magma.sh

FROM base as jni
# Install java jni header
ADD ./common/install_jni.sh install_jni.sh
ADD ./java/jni.h jni.h
RUN bash ./install_jni.sh && rm install_jni.sh

FROM ${GPU_IMAGE} as common
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
RUN yum install -y \
        aclocal \
        autoconf \
        automake \
        bison \
        bzip2 \
        curl \
        diffutils \
        file \
        git \
        make \
        patch \
        perl \
        unzip \
        util-linux \
        wget \
        which \
        xz \
        yasm \

ENV SSL_CERT_FILE=/opt/_internal/certs.pem
COPY --from=python   /opt/python                           /opt/python
COPY --from=python   /opt/_internal                        /opt/_internal
COPY --from=python   /opt/python/cp36-cp36m/bin/auditwheel /usr/local/bin/auditwheel
COPY --from=intel    /opt/intel                            /opt/intel
COPY --from=patchelf /usr/local/bin/patchelf               /usr/local/bin/patchelf
COPY --from=jni      /usr/local/include/jni.h              /usr/local/include/jni.h

FROM common as cuda_final
ARG BASE_CUDA_VERSION=10.1
RUN yum install -y yum-utils centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran devtoolset-7-binutils
ENV PATH=/opt/rh/devtoolset-7/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:$LD_LIBRARY_PATH

RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm -ivh epel-release-latest-7.noarch.rpm && \
    rm -f epel-release-latest-7.noarch.rpm

# cmake
RUN yum install -y cmake3 && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

RUN rm -rf /usr/local/cuda-${BASE_CUDA_VERSION}
COPY --from=cuda     /usr/local/cuda-${BASE_CUDA_VERSION}  /usr/local/cuda-${BASE_CUDA_VERSION}
COPY --from=magma    /usr/local/cuda-${BASE_CUDA_VERSION}  /usr/local/cuda-${BASE_CUDA_VERSION}

FROM common as rocm_final
ARG ROCM_VERSION=3.7
# Install ROCm
ADD ./common/install_rocm.sh install_rocm.sh
RUN bash ./install_rocm.sh ${ROCM_VERSION} && rm install_rocm.sh
# cmake is already installed inside the rocm base image, but both 2 and 3 exist
RUN yum install -y cmake3 && \
    rm -f /usr/bin/cmake && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

