# syntax = docker/dockerfile:experimental
ARG BASE_CUDA_VERSION=10.1
FROM quay.io/pypa/manylinux2014_x86_64 as python
# remove unncessary python versions
RUN rm -rf /opt/python/cp27* /opt/_internal/cpython-2.7*
RUN rm -rf /opt/python/cp35* /opt/_internal/cpython-3.5*

FROM python as libcrypt
RUN mkdir -p /libcrypt && find /usr/local/lib -type f -name "libcrypt*" -exec cp -L {} /libcrypt \;
RUN mkdir -p /libcrypt64 && find /usr/lib64 -type f -name "libcrypt*" -exec cp -L {} /libcrypt64 \;
# Allows us to restore all the links, since copying them wasn't tenable
RUN for link in $(find / -name "libcrypt*" -type l); do echo "ln -sf $(readlink -f ${link})  ${link}" >> /relink_libcrypt; done

FROM nvidia/cuda:${BASE_CUDA_VERSION}-devel-centos7 as base
ARG BASE_CUDA_VERSION=10.1
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
RUN yum install -y \
        automake \
        bison \
        bzip2 \
        curl \
        diffutils \
        file \
        git \
        openssl \
        openssl-devel \
        patch \
        perl \
        unzip \
        util-linux \
        wget \
        which \
        xz \
        yasm
RUN yum install -y yum-utils centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran devtoolset-7-binutils
ENV PATH=/opt/rh/devtoolset-7/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:$LD_LIBRARY_PATH

RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm -ivh epel-release-latest-7.noarch.rpm && \
    rm -f epel-release-latest-7.noarch.rpm

# cmake
RUN yum install -y cmake3 && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

RUN yum install -y autoconf aclocal automake make

FROM base as cuda
ARG BASE_CUDA_VERSION=10.1
# Install CUDA
ADD ./common/install_cuda.sh install_cuda.sh
RUN bash ./install_cuda.sh ${BASE_CUDA_VERSION} && rm install_cuda.sh

FROM base as intel
# MKL
ADD ./common/install_mkl.sh install_mkl.sh
RUN bash ./install_mkl.sh && rm install_mkl.sh

# EPEL for cmake FROM python as patchelf
FROM base as patchelf
# Install patchelf
ADD ./common/install_patchelf.sh install_patchelf.sh
RUN bash ./install_patchelf.sh && rm install_patchelf.sh

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

FROM base as final

RUN rm -rf /usr/local/cuda-${BASE_CUDA_VERSION}

ENV SSL_CERT_FILE=/opt/_internal/certs.pem
COPY --from=python   /opt/python                           /opt/python
COPY --from=python   /opt/_internal                        /opt/_internal
COPY --from=python   /opt/python/cp37-cp37m/bin/auditwheel /usr/local/bin/auditwheel
COPY --from=libcrypt /libcrypt                             /usr/local/lib/
COPY --from=libcrypt /libcrypt64                           /usr/lib64/
COPY --from=libcrypt /relink_libcrypt                      /relink_libcrypt
RUN bash /relink_libcrypt
COPY --from=cuda     /usr/local/cuda-${BASE_CUDA_VERSION}  /usr/local/cuda-${BASE_CUDA_VERSION}
COPY --from=intel    /opt/intel                            /opt/intel
COPY --from=patchelf /usr/local/bin/patchelf               /usr/local/bin/patchelf
COPY --from=magma    /usr/local/cuda-${BASE_CUDA_VERSION}  /usr/local/cuda-${BASE_CUDA_VERSION}
COPY --from=jni      /usr/local/include/jni.h              /usr/local/include/jni.h
