ARG CUDA_VERSION=10.2
ARG BASE_TARGET=cuda${CUDA_VERSION}
FROM nvidia/cuda:9.2-devel-centos7 as base

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN yum install -y wget curl perl util-linux xz bzip2 git patch which unzip
RUN yum install -y yum-utils centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran devtoolset-7-binutils
# EPEL for cmake
RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm -ivh epel-release-latest-7.noarch.rpm && \
    rm -f epel-release-latest-7.noarch.rpm
# cmake
RUN yum install -y cmake3 && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake
ENV PATH=/opt/rh/devtoolset-7/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:$LD_LIBRARY_PATH

RUN yum install -y autoconf aclocal automake make sudo
RUN rm -rf /usr/local/cuda-*

FROM base as patchelf
# Install patchelf
ADD ./common/install_patchelf.sh install_patchelf.sh
RUN bash ./install_patchelf.sh && rm install_patchelf.sh && cp $(which patchelf) /patchelf

FROM base as openssl
# Install openssl
ADD ./common/install_openssl.sh install_openssl.sh
RUN bash ./install_openssl.sh && rm install_openssl.sh

FROM base as vulkansdk
# Install vulkan sdk
ADD ./common/install_vulkan_sdk.sh install_vulkan_sdk.sh
RUN bash ./install_vulkan_sdk.sh 1.2.162.1 && rm install_vulkan_sdk.sh

FROM base as conda
# Install Anaconda
ADD ./common/install_conda.sh install_conda.sh
RUN bash ./install_conda.sh && rm install_conda.sh

# Install CUDA
FROM base as cuda
RUN rm -rf /usr/local/cuda-*
ADD ./common/install_cuda.sh install_cuda.sh

FROM cuda as cuda9.2
RUN bash ./install_cuda.sh 9.2
ENV DESIRED_CUDA=9.2

FROM cuda as cuda10.1
RUN bash ./install_cuda.sh 10.1
ENV DESIRED_CUDA=10.1

FROM cuda as cuda10.2
RUN bash ./install_cuda.sh 10.2
ENV DESIRED_CUDA=10.2

FROM cuda as cuda11.0
RUN bash ./install_cuda.sh 11.0
ENV DESIRED_CUDA=11.0

FROM cuda as cuda11.1
RUN bash ./install_cuda.sh 11.1
ENV DESIRED_CUDA=11.1

FROM cuda as cuda11.2
RUN bash ./install_cuda.sh 11.2
ENV DESIRED_CUDA=11.2

FROM cuda as cuda11.3
RUN bash ./install_cuda.sh 11.3
ENV DESIRED_CUDA=11.3

# Install MNIST test data
FROM base as mnist
ADD ./common/install_mnist.sh install_mnist.sh
RUN bash ./install_mnist.sh

FROM base as all_cuda
COPY --from=cuda9.2   /usr/local/cuda-9.2  /usr/local/cuda-9.2
COPY --from=cuda10.1  /usr/local/cuda-10.1 /usr/local/cuda-10.1
COPY --from=cuda10.2  /usr/local/cuda-10.2 /usr/local/cuda-10.2
COPY --from=cuda11.0  /usr/local/cuda-11.0 /usr/local/cuda-11.0
COPY --from=cuda11.1  /usr/local/cuda-11.1 /usr/local/cuda-11.1
COPY --from=cuda11.2  /usr/local/cuda-11.2 /usr/local/cuda-11.2
COPY --from=cuda11.3  /usr/local/cuda-11.3 /usr/local/cuda-11.3

FROM ${BASE_TARGET} as final
# Install LLVM
COPY --from=pytorch/llvm:9.0.1 /opt/llvm              /opt/llvm
COPY --from=pytorch/llvm:9.0.1 /opt/llvm_no_cxx11_abi /opt/llvm_no_cxx11_abi
COPY --from=openssl            /opt/openssl           /opt/openssl
COPY --from=patchelf           /patchelf              /usr/local/bin/patchelf
COPY --from=vulkansdk          /opt/vulkansdk         /opt/vulkansdk
COPY --from=conda              /opt/conda             /opt/conda
ADD  ./java/jni.h /usr/local/include/jni.h
ENV  PATH /opt/conda/bin:$PATH
COPY --from=mnist  /usr/local/mnist /usr/local/mnist
RUN rm -rf /usr/local/cuda
RUN chmod o+rw /usr/local
RUN touch /.condarc && \
    chmod o+rw /.condarc && \
    chmod -R o+rw /opt/conda
