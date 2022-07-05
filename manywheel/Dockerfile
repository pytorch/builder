# syntax = docker/dockerfile:experimental
ARG ROCM_VERSION=3.7
ARG BASE_CUDA_VERSION=10.1

ARG GPU_IMAGE=nvidia/cuda:${BASE_CUDA_VERSION}-devel-centos7
FROM centos:7 as base

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ARG DEVTOOLSET_VERSION=9
RUN yum install -y wget curl perl util-linux xz bzip2 git patch which perl zlib-devel
RUN yum install -y yum-utils centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y devtoolset-${DEVTOOLSET_VERSION}-gcc devtoolset-${DEVTOOLSET_VERSION}-gcc-c++ devtoolset-${DEVTOOLSET_VERSION}-gcc-gfortran devtoolset-${DEVTOOLSET_VERSION}-binutils
ENV PATH=/opt/rh/devtoolset-${DEVTOOLSET_VERSION}/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-${DEVTOOLSET_VERSION}/root/usr/lib64:/opt/rh/devtoolset-${DEVTOOLSET_VERSION}/root/usr/lib:$LD_LIBRARY_PATH

RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm -ivh epel-release-latest-7.noarch.rpm && \
    rm -f epel-release-latest-7.noarch.rpm

# cmake
RUN yum install -y cmake3 && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

RUN yum install -y autoconf aclocal automake make

FROM base as openssl
# Install openssl (this must precede `build python` step)
# (In order to have a proper SSL module, Python is compiled
# against a recent openssl [see env vars above], which is linked
# statically. We delete openssl afterwards.)
ADD ./common/install_openssl.sh install_openssl.sh
RUN bash ./install_openssl.sh && rm install_openssl.sh

FROM base as python
# build python
COPY manywheel/build_scripts /build_scripts
ADD ./common/install_cpython.sh /build_scripts/install_cpython.sh
RUN bash build_scripts/build.sh && rm -r build_scripts

# remove unncessary python versions
RUN rm -rf /opt/python/cp26-cp26m /opt/_internal/cpython-2.6.9-ucs2
RUN rm -rf /opt/python/cp26-cp26mu /opt/_internal/cpython-2.6.9-ucs4
RUN rm -rf /opt/python/cp33-cp33m /opt/_internal/cpython-3.3.6
RUN rm -rf /opt/python/cp34-cp34m /opt/_internal/cpython-3.4.6

FROM base as cuda
ARG BASE_CUDA_VERSION=10.2
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
ARG BASE_CUDA_VERSION=10.2
# Install magma
ADD ./common/install_magma.sh install_magma.sh
RUN bash ./install_magma.sh ${BASE_CUDA_VERSION} && rm install_magma.sh

FROM base as jni
# Install java jni header
ADD ./common/install_jni.sh install_jni.sh
ADD ./java/jni.h jni.h
RUN bash ./install_jni.sh && rm install_jni.sh

FROM base as libpng
# Install libpng
ADD ./common/install_libpng.sh install_libpng.sh
RUN bash ./install_libpng.sh && rm install_libpng.sh

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
        yasm
RUN yum install -y \
    https://repo.ius.io/ius-release-el7.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum swap -y git git236-core
# git236+ would refuse to run git commands in repos owned by other users
# Which causes version check to fail, as pytorch repo is bind-mounted into the image
# Override this behaviour by treating every folder as safe
# For more details see https://github.com/pytorch/pytorch/issues/78659#issuecomment-1144107327
RUN git config --global --add safe.directory "*"

ENV SSL_CERT_FILE=/opt/_internal/certs.pem
# Install LLVM version
COPY --from=pytorch/llvm:9.0.1 /opt/llvm                             /opt/llvm
COPY --from=pytorch/llvm:9.0.1 /opt/llvm_no_cxx11_abi                /opt/llvm_no_cxx11_abi
COPY --from=openssl            /opt/openssl                          /opt/openssl
COPY --from=python             /opt/python                           /opt/python
COPY --from=python             /opt/_internal                        /opt/_internal
COPY --from=python             /opt/python/cp37-cp37m/bin/auditwheel /usr/local/bin/auditwheel
COPY --from=intel              /opt/intel                            /opt/intel
COPY --from=patchelf           /usr/local/bin/patchelf               /usr/local/bin/patchelf
COPY --from=jni                /usr/local/include/jni.h              /usr/local/include/jni.h
COPY --from=libpng             /usr/local/bin/png*                   /usr/local/bin/
COPY --from=libpng             /usr/local/bin/libpng*                /usr/local/bin/
COPY --from=libpng             /usr/local/include/png*               /usr/local/include/
COPY --from=libpng             /usr/local/include/libpng*            /usr/local/include/
COPY --from=libpng             /usr/local/lib/libpng*                /usr/local/lib/
COPY --from=libpng             /usr/local/lib/pkgconfig              /usr/local/lib/pkgconfig

FROM common as cpu_final
ARG BASE_CUDA_VERSION=10.1
ARG DEVTOOLSET_VERSION=9
RUN yum install -y yum-utils centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y devtoolset-${DEVTOOLSET_VERSION}-gcc devtoolset-${DEVTOOLSET_VERSION}-gcc-c++ devtoolset-${DEVTOOLSET_VERSION}-gcc-gfortran devtoolset-${DEVTOOLSET_VERSION}-binutils
ENV PATH=/opt/rh/devtoolset-${DEVTOOLSET_VERSION}/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-${DEVTOOLSET_VERSION}/root/usr/lib64:/opt/rh/devtoolset-${DEVTOOLSET_VERSION}/root/usr/lib:$LD_LIBRARY_PATH

# cmake
RUN yum install -y cmake3 && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

# ninja
RUN yum install -y http://repo.okay.com.mx/centos/7/x86_64/release/okay-release-1-5.el7.noarch.rpm
RUN yum install -y ninja-build

FROM cpu_final as cuda_final
RUN rm -rf /usr/local/cuda-${BASE_CUDA_VERSION}
COPY --from=cuda     /usr/local/cuda-${BASE_CUDA_VERSION}  /usr/local/cuda-${BASE_CUDA_VERSION}
COPY --from=magma    /usr/local/cuda-${BASE_CUDA_VERSION}  /usr/local/cuda-${BASE_CUDA_VERSION}

FROM common as rocm_final
ARG ROCM_VERSION=3.7
ARG PYTORCH_ROCM_ARCH
ENV PYTORCH_ROCM_ARCH ${PYTORCH_ROCM_ARCH}
# Install ROCm
ADD ./common/install_rocm.sh install_rocm.sh
RUN ROCM_VERSION=${ROCM_VERSION} bash ./install_rocm.sh && rm install_rocm.sh
ADD ./common/install_rocm_drm.sh install_rocm_drm.sh
RUN bash ./install_rocm_drm.sh && rm install_rocm_drm.sh
ADD ./common/install_rocm_magma.sh install_rocm_magma.sh
RUN bash ./install_rocm_magma.sh && rm install_rocm_magma.sh
# cmake is already installed inside the rocm base image, but both 2 and 3 exist
# cmake3 is needed for the later MIOpen custom build, so that step is last.
RUN yum install -y cmake3 && \
    rm -f /usr/bin/cmake && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake
ADD ./common/install_miopen.sh install_miopen.sh
RUN bash ./install_miopen.sh ${ROCM_VERSION} && rm install_miopen.sh
