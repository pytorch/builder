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

RUN yum install -y autoconf aclocal automake make

FROM base as patchelf
# Install patchelf
ADD ./common/install_patchelf.sh install_patchelf.sh
RUN bash ./install_patchelf.sh && rm install_patchelf.sh && cp $(which patchelf) /patchelf

FROM base as conda
# Install Anaconda
ADD ./common/install_conda.sh install_conda.sh
RUN bash ./install_conda.sh && rm install_conda.sh

# Install CUDA
FROM base as cuda
ADD ./common/install_cuda.sh install_cuda.sh

FROM cuda as cuda92
RUN bash ./install_cuda.sh 9.2

FROM cuda as cuda100
RUN bash ./install_cuda.sh 10.0

FROM cuda as cuda101
RUN bash ./install_cuda.sh 10.1

FROM cuda as cuda102
RUN bash ./install_cuda.sh 10.2

# Instal MNIST test data
FROM base as mnist
ADD ./common/install_mnist.sh install_mnist.sh
RUN bash ./install_mnist.sh

FROM base as final
COPY --from=patchelf /patchelf            /usr/local/bin/patchelf
COPY --from=conda    /opt/conda           /opt/conda
RUN rm -rf /usr/local/cuda-*
COPY --from=cuda92   /usr/local/cuda-9.2  /usr/local/cuda-9.2
COPY --from=cuda100  /usr/local/cuda-10.0 /usr/local/cuda-10.0
COPY --from=cuda101  /usr/local/cuda-10.1 /usr/local/cuda-10.1
COPY --from=cuda102  /usr/local/cuda-10.2 /usr/local/cuda-10.2
ADD ./java/jni.h     /usr/local/include/jni.h
ENV PATH /opt/conda/bin:$PATH
COPY --from=mnist  /usr/local/mnist /usr/local/mnist
