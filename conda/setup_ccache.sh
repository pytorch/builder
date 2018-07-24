# sets up ccache inside the docker image (when debugging)
if ! ls ~/ccache/bin/ccache
then
    yum install -y automake autoconf
    yum install -y asciidoc
    mkdir -p ~/ccache
    pushd /tmp
    rm -rf ccache
    git clone https://github.com/colesbury/ccache -b ccbin
    pushd ccache
    ./autogen.sh
    ./configure
    make install prefix=~/ccache
    popd
    popd

    mkdir -p ~/ccache/lib
    mkdir -p ~/ccache/cuda
    ln -s ~/ccache/bin/ccache ~/ccache/lib/cc
    ln -s ~/ccache/bin/ccache ~/ccache/lib/c++
    ln -s ~/ccache/bin/ccache ~/ccache/lib/gcc
    ln -s ~/ccache/bin/ccache ~/ccache/lib/g++
    ln -s ~/ccache/bin/ccache ~/ccache/cuda/nvcc

    ~/ccache/bin/ccache -M 25Gi
fi

export PATH=~/ccache/lib:$PATH
export CUDA_NVCC_EXECUTABLE=~/ccache/cuda/nvcc
