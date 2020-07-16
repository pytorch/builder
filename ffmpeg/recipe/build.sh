#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

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
