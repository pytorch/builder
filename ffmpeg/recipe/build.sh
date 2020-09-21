#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

if [[ "$(uname)" == Darwin ]]; then
   export CONDA_BUILD_SYSROOT=$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk
fi

./configure \
        --prefix="${PREFIX}" \
        --cc=${CC} \
        --disable-doc \
        --disable-openssl \
        --enable-avresample \
        --enable-gnutls \
        --enable-hardcoded-tables \
        --enable-libfreetype \
        --enable-libopenh264 \
        --enable-pic \
        --enable-pthreads \
        --enable-shared \
        --disable-static \
        --enable-version3 \
        --enable-zlib \
	    --enable-libmp3lame

make -j${CPU_COUNT}
make install -j${CPU_COUNT}
