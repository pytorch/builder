FROM nvidia/cuda:8.0-devel-centos6

RUN yum install -y git wget curl

ENV CUDNN_VERSION 6.0.21

RUN CUDNN_DOWNLOAD_SUM=9b09110af48c9a4d7b6344eb4b3e344daa84987ed6177d5c44319732f3bb7f9c && \
    curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-8.0-linux-x64-v6.0.tgz -O && \
    echo "$CUDNN_DOWNLOAD_SUM  cudnn-8.0-linux-x64-v6.0.tgz" | sha256sum -c - && \
    tar -xzf cudnn-8.0-linux-x64-v6.0.tgz -C /usr/local && \
    rm cudnn-8.0-linux-x64-v6.0.tgz && \
    ldconfig

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
ENV PATH=/opt/rh/devtoolset-3/root/usr/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-3/root/usr/lib64:/opt/rh/devtoolset-3/root/usr/lib:$LD_LIBRARY_PATH


# cmake
RUN yum install -y cmake
COPY build_scripts /build_scripts
RUN bash build_scripts/build.sh && rm -r build_scripts

ENV SSL_CERT_FILE=/opt/_internal/certs.pem

RUN rm -rf /opt/python/cp26-cp26m /opt/_internal/cpython-2.6.9-ucs2
RUN rm -rf /opt/python/cp26-cp26mu /opt/_internal/cpython-2.6.9-ucs4
RUN rm -rf /opt/python/cp33-cp33m /opt/_internal/cpython-3.3.6
RUN rm -rf /opt/python/cp34-cp34m /opt/_internal/cpython-3.4.6

# COPY l_mkl_2017.2.174.tgz /

# RUN tar -xvf l_mkl_2017.2.174.tgz && \
#     pushd l_mkl_2017.2.174 && \
#     sed -i 's/ACCEPT_EULA=decline/ACCEPT_EULA=accept/g' silent.cfg && \
#     ./install.sh --silent silent.cfg && \
#     popd && \
#     rm -rf l_mkl_2017.2.174* 

RUN wget http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11306/l_mkl_2017.2.174.tgz && \
    tar -xvf l_mkl_2017.2.174.tgz && \
    pushd l_mkl_2017.2.174 && \
    sed -i 's/ACCEPT_EULA=decline/ACCEPT_EULA=accept/g' silent.cfg && \
    ./install.sh --silent silent.cfg && \
    popd && \
    rm -rf l_mkl_2017.2.174* && \
    find /opt/intel -type f | grep -v "/opt/intel/compilers_and_libraries_2017.2.174/linux/mkl/lib/intel64_lin" | xargs rm -f && \
    find /opt/intel -type f -name "*.a" | xargs rm -f

ENV CMAKE_LIBRARY_PATH="/opt/intel/compilers_and_libraries_2017.2.174/linux/mkl/lib/intel64_lin"

