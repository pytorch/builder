FROM nvidia/cuda:8.0-cudnn5-devel-centos6

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# get devtoolset-3
RUN yum install -y yum-utils
RUN yum install -y centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y devtoolset-3-gcc
RUN yum install -y devtoolset-3-gcc-c++
RUN yum install -y devtoolset-3-gcc-gfortran
RUN yum install -y devtoolset-3-binutils
RUN yum install -y git wget curl
ENV PATH=/opt/rh/devtoolset-3/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-3/root/usr/lib64:/opt/rh/devtoolset-3/root/usr/lib:$LD_LIBRARY_PATH


# cmake
RUN yum install -y cmake
COPY build_scripts /build_scripts
RUN bash build_scripts/build.sh && rm -r build_scripts

ENV SSL_CERT_FILE=/opt/_internal/certs.pem