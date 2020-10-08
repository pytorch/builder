# ffmpeg-win-lgpl
MXE-based cross-compilation workflow for producing FFMpeg LGPL binaries for Windows on Linux.

## Overview
This repository provides LGPL binary distributions of FFMpeg for Windows. The compilation is based on the [M cross environment](https://github.com/mxe/mxe) (MXE) to compile the binaries from Linux. The compilation is performed on a CentOS 7 Docker image to ensure manylinux compatibility on Python.

## Docker image
We provide a Docker image with all the MXE packages already compiled at `andfoy/ffmpeg-win-lgpl`, however it is possible to build the image from scratch:

```bash
docker build --tag ffmpeg-win-lgpl .
```

**Note:** Because MXE compiles all the binary dependencies required to build FFmpeg from scratch, this process may take more than two hours depending on your machine.

## Compilling FFmpeg
To compile FFmpeg, it is possible to execute the ``build_ffmpeg.sh`` script found at the root of this repository using the corresponding Docker image:

```bash
mkdir ffmpeg_output
docker run --rm -i \
-v $(pwd)/ffmpeg_output:ffmpeg-build-src/ffmpeg_output \
"andfoy/ffmpeg-win-lgpl" \
build_ffmpeg.sh
```

### Compilation flags
This distribution of FFmpeg is LGPL-compliant and it is compiled with the following flags:

```
--disable-doc
--disable-openssl
--enable-avresample
--enable-gnutls
--enable-hardcoded-tables
--enable-libfreetype
--enable-libopenh264
--enable-pic
--disable-w32threads
--enable-shared
--disable-static
--enable-version3
--enable-zlib
--enable-libmp3lame
```
