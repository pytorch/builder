#!/bin/bash

set -ex

FFMPEG_VERSION=4.2
OPENH264_VERSION=2.1.1

# Download OpenH264
wget https://github.com/cisco/openh264/archive/v$OPENH264_VERSION.tar.gz
tar -xvzf v$OPENH264_VERSION.tar.gz
rm -rf v$OPENH264_VERSION.tar.gz
pushd openh264-$OPENH264_VERSION

make
make install
popd
rm -rf openh264-$OPENH264_VERSION

# Download FFmpeg
wget https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.gz
tar -xvzf ffmpeg-$FFMPEG_VERSION.tar.gz
rm -rf ffmpeg-$FFMPEG_VERSION.tar.gz

pushd ffmpeg-$FFMPEG_VERSION
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/ \
./configure \
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

make -j$(nproc)
make install
popd
rm -rf ffmpeg-$FFMPEG_VERSION
