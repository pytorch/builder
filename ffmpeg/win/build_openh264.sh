#! /bin/bash

export PATH=$(pwd)/mxe/usr/bin:$(pwd)/mxe/usr/x86_64-pc-linux-gnu/bin:$PATH

# Clone OpenH264
git clone https://github.com/cisco/openh264.git
pushd openh264

# Compile OpenH264
make  \
OS=mingw_nt \
ARCH=x86_64 \
CC=x86_64-w64-mingw32.shared-gcc \
CXX=x86_64-w64-mingw32.shared-g++ \
AR=x86_64-w64-mingw32.shared-ar

# Install OpenH264
make  \
OS=mingw_nt \
ARCH=x86_64 \
CC=x86_64-w64-mingw32.shared-gcc \
MXE_TARGETS="x86_64-w64-mingw32.shared" \
DESTDIR=../mxe/usr/x86_64-w64-mingw32.shared/ \
install

popd

# Apply pkgconfig patch
pushd mxe/usr/x86_64-w64-mingw32.shared/usr/local/lib/pkgconfig
patch openh264.pc < /ffmpeg-build-src/openh264.pc.patch
popd

cp \
mxe/usr/x86_64-w64-mingw32.shared/usr/local/lib/pkgconfig/openh264.pc \
mxe/usr/x86_64-w64-mingw32.shared/lib/pkgconfig/
