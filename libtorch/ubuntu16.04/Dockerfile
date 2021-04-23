ARG BASE_TARGET=base
FROM nvidia/cuda:9.2-devel-ubuntu16.04 as base

RUN apt-get clean && apt-get update
RUN apt-get install -y curl locales git-all autoconf automake make cmake wget unzip

RUN locale-gen en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

FROM base as openssl
# Install openssl
ADD ./common/install_openssl.sh install_openssl.sh
RUN bash ./install_openssl.sh && rm install_openssl.sh

FROM base as intel
# Install MKL
ADD ./common/install_mkl.sh install_mkl.sh
RUN bash ./install_mkl.sh && rm install_mkl.sh

FROM base as cuda
ADD ./common/install_cuda.sh install_cuda.sh
ADD ./common/install_magma.sh install_magma.sh
ENV CUDA_HOME /usr/local/cuda

FROM base as conda
ADD ./common/install_conda.sh install_conda.sh
RUN bash ./install_conda.sh && rm install_conda.sh
RUN /opt/conda/bin/conda install -y cmake=3.14

FROM cuda as cuda9.2
RUN bash ./install_cuda.sh 9.2
RUN bash ./install_magma.sh 9.2

FROM cuda as cuda10.1
RUN bash ./install_cuda.sh 10.1
RUN bash ./install_magma.sh 10.1

FROM cuda as cuda10.2
RUN bash ./install_cuda.sh 10.2
RUN bash ./install_magma.sh 10.2

FROM cuda as cuda11.0
RUN bash ./install_cuda.sh 11.0
RUN bash ./install_magma.sh 11.0

FROM cuda as cuda11.1
RUN bash ./install_cuda.sh 11.1
RUN bash ./install_magma.sh 11.1

FROM cuda as cuda11.2
RUN bash ./install_cuda.sh 11.2
RUN bash ./install_magma.sh 11.2

# Install LLVM
COPY --from=pytorch/llvm:9.0.1 /opt/llvm /opt/llvm

FROM ${BASE_TARGET} as final
# Install patchelf
ADD ./common/install_patchelf.sh install_patchelf.sh
RUN bash ./install_patchelf.sh && rm install_patchelf.sh
COPY --from=intel /opt/intel /opt/intel
# Install Anaconda
COPY --from=conda /opt/conda /opt/conda
ENV PATH /opt/conda/bin:$PATH

COPY --from=openssl  /usr/local/lib/libcrypto.so.1.1       /usr/local/lib/libcrypto.so.1.1
COPY --from=openssl  /usr/local/lib/libssl.so.1.1          /usr/local/lib/libssl.so.1.1
COPY --from=openssl  /usr/local/include/openssl/*          /usr/local/include/openssl/
COPY --from=openssl  /usr/local/lib/libcrypto.a            /usr/local/lib/libcrypto.a
COPY --from=openssl  /usr/local/lib/libssl.a               /usr/local/lib/libssl.a
COPY --from=openssl  /usr/local/lib/pkgconfig/libcrypto.pc /usr/local/lib/pkgconfig/libcrypto.pc
COPY --from=openssl  /usr/local/lib/pkgconfig/libssl.pc    /usr/local/lib/pkgconfig/libssl.pc
COPY --from=openssl  /usr/local/lib/pkgconfig/openssl.pc   /usr/local/lib/pkgconfig/openssl.pc
COPY --from=openssl  /usr/local/lib/engines-1.1/afalg.so   /usr/local/lib/engines-1.1/afalg.so
COPY --from=openssl  /usr/local/lib/engines-1.1/capi.so    /usr/local/lib/engines-1.1/capi.so
COPY --from=openssl  /usr/local/lib/engines-1.1/padlock.so /usr/local/lib/engines-1.1/padlock.so
COPY --from=openssl  /usr/local/bin/openssl                /usr/local/bin/openssl
COPY --from=openssl  /usr/local/bin/c_rehash               /usr/local/bin/c_rehash
RUN ln -s /usr/local/lib/libcrypto.so.1.1                  /usr/local/lib/libcrypto.so
RUN ln -s /usr/local/lib/libssl.so.1.1                     /usr/local/lib/libssl.so
