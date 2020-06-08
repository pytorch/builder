FROM nvidia/cuda:9.2-devel-ubuntu16.04 as base

RUN apt-get clean && apt-get update
RUN apt-get install -y curl locales git-all autoconf automake make wget unzip

RUN locale-gen en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

FROM base as intel
RUN mkdir -p /opt/intel/lib
WORKDIR /tmp
RUN curl -fsSL https://anaconda.org/intel/mkl-static/2019.5/download/linux-64/mkl-static-2019.5-intel_281.tar.bz2 | tar xjv
RUN mv lib/* /opt/intel/lib/
RUN curl -fsSL https://anaconda.org/intel/mkl-include/2019.5/download/linux-64/mkl-include-2019.5-intel_281.tar.bz2 | tar xjv
RUN mv include /opt/intel/

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

FROM cuda as cuda110
RUN bash ./install_cuda.sh 11.0

FROM base as final
# Install patchelf
ADD ./common/install_patchelf.sh install_patchelf.sh
RUN bash ./install_patchelf.sh && rm install_patchelf.sh

# Install MKL
ADD ./common/install_mkl.sh install_mkl.sh
RUN bash ./install_mkl.sh && rm install_mkl.sh

# Install MAGMA (need CUDA)
ADD ./common/install_magma.sh install_magma.sh
RUN bash ./install_magma.sh 9.2 10.0 10.1 10.2 && rm install_magma.sh

# Install Anaconda
ENV PATH /opt/conda/bin:$PATH
ADD ./common/install_conda.sh install_conda.sh
RUN bash ./install_conda.sh && rm install_conda.sh

RUN rm -rf /usr/local/cuda-*
COPY --from=cuda92   /usr/local/cuda-9.2  /usr/local/cuda-9.2
COPY --from=cuda100  /usr/local/cuda-10.0 /usr/local/cuda-10.0
COPY --from=cuda101  /usr/local/cuda-10.1 /usr/local/cuda-10.1
COPY --from=cuda102  /usr/local/cuda-10.2 /usr/local/cuda-10.2
COPY --from=cuda110  /usr/local/cuda-11.0 /usr/local/cuda-11.0
COPY --from=intel /opt/intel /opt/intel
ENV CUDA_HOME /usr/local/cuda
