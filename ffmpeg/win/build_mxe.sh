#! /bin/bash
# ---- Clone MXE -----
git clone https://github.com/mxe/mxe.git
pushd mxe

# ---- Install FFmpeg dependencies -----
# CMake
make MXE_TARGETS="x86_64-w64-mingw32.shared" cmake

# bzip2
make MXE_TARGETS="x86_64-w64-mingw32.shared" bzip2

# libiconv
make MXE_TARGETS="x86_64-w64-mingw32.shared" libiconv

# YASM
make MXE_TARGETS="x86_64-w64-mingw32.shared" yasm

# NASM
make MXE_TARGETS="x86_64-w64-mingw32.shared" nasm

# OpenSSL
make MXE_TARGETS="x86_64-w64-mingw32.shared" openssl

# SDL2
make MXE_TARGETS="x86_64-w64-mingw32.shared" sdl2

# ZLib
make MXE_TARGETS="x86_64-w64-mingw32.shared" zlib

# FreeType
make MXE_TARGETS="x86_64-w64-mingw32.shared" freetype

# Vorbis
make MXE_TARGETS="x86_64-w64-mingw32.shared" vorbis

# Theora
make MXE_TARGETS="x86_64-w64-mingw32.shared" theora

# TurboJPEG
make MXE_TARGETS="x86_64-w64-mingw32.shared" libjpeg-turbo

# LibPNG
make MXE_TARGETS="x86_64-w64-mingw32.shared" libpng

# LAME
make MXE_TARGETS="x86_64-w64-mingw32.shared" lame

# GNU TLS
make MXE_TARGETS="x86_64-w64-mingw32.shared" gnutls

popd
