FROM ubuntu:xenial as dev
ARG LLVM_VERSION=9.0.1
ENV LLVM_URL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y \
        build-essential \
        curl \
        cmake \
        make \
        python3 \
        python3-dev \
        xz-utils

# Build LLVM with CXX11 ABI (default)
RUN mkdir -p /opt/llvm /tmp/llvm/build
WORKDIR /tmp/llvm
RUN curl -fL -o llvm.tar.xz "${LLVM_URL}" && \
        tar -xf llvm.tar.xz --strip-components=1
WORKDIR /tmp/llvm/build
RUN cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DCMAKE_INSTALL_PREFIX=/opt/llvm \
        -DLLVM_TARGETS_TO_BUILD="host" \
        -DLLVM_BUILD_TOOLS=OFF \
        -DLLVM_BUILD_UTILS=OFF \
        -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON \
        ../
RUN make -j"$(nproc --ignore=2)" && make install

# Build LLVM without CXX11 ABI
RUN mkdir -p /opt/llvm_no_cxx11_abi /tmp/llvm/build_no_cxx11_abi
WORKDIR /tmp/llvm/build_no_cxx11_abi
RUN cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DCMAKE_INSTALL_PREFIX=/opt/llvm_no_cxx11_abi \
        -DLLVM_TARGETS_TO_BUILD="host" \
        -DLLVM_BUILD_TOOLS=OFF \
        -DLLVM_BUILD_UTILS=OFF \
        -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON \
	-DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 \
        ../
RUN make -j"$(nproc --ignore=2)" && make install


FROM scratch as final
COPY --from=dev /opt/llvm /opt/llvm
COPY --from=dev /opt/llvm_no_cxx11_abi /opt/llvm_no_cxx11_abi
