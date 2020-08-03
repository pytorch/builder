# FFmpeg

## Building

To build just run:

```
./build.sh
```

This should give you a docker image with `devtoolset3` installed in order to keep binary size down.
Outputted binaries should be in the `output` folder

## Pushing

Once you have built the binaries push them with:

```
anaconda upload -u pytorch --force output/*/ffmpeg*.bz2
```

If you do not have upload permissions, please ping @seemethere or @soumith to gain access

## Licensing
FFmpeg was compiled without the GPL components enabled, thus being LGPL-licensed. The LICENSE notice is included as part of this repository and the compilation flags are described as follows:

### Linux and Mac
Linux binaries were compiled using the [official FFmpeg source files](http://ffmpeg.org/releases/), and compiled with the following flags:

```
--disable-doc
--disable-openssl
--enable-avresample
--enable-gnutls
--enable-hardcoded-tables
--enable-libfreetype
--enable-libopenh264
--enable-pic
--enable-pthreads
--enable-shared
--disable-static
--enable-version3
--enable-zlib
--enable-libmp3lame
```

### Windows
Windows binaries are redistributed from the LGPL [Zeranoe FFmpeg Builds](http://ffmpeg.zeranoe.com/builds/), which define the following flags:

```
--disable-static
  --enable-shared
  --enable-version3
  --enable-sdl2
  --enable-fontconfig
  --enable-gnutls
  --enable-iconv
  --enable-libass
  --enable-libdav1d
  --enable-libbluray
  --enable-libfreetype
  --enable-libmp3lame
  --enable-libopencore-amrnb
  --enable-libopencore-amrwb
  --enable-libopenjpeg
  --enable-libopus
  --enable-libshine
  --enable-libsnappy
  --enable-libsoxr
  --enable-libsrt
  --enable-libtheora
  --enable-libtwolame
  --enable-libvpx
  --enable-libwavpack
  --enable-libwebp
  --enable-libxml2
  --enable-libzimg
  --enable-lzma
  --enable-zlib
  --enable-gmp
  --enable-libvmaf
  --enable-libvorbis
  --enable-libvo-amrwbenc
  --enable-libmysofa
  --enable-libspeex
  --enable-libaom
  --enable-libgsm
  --disable-w32threads
  --enable-libmfx
  --enable-ffnvcodec
  --enable-cuda-llvm
  --enable-cuvid
  --enable-d3d11va
  --enable-nvenc
  --enable-nvdec
  --enable-dxva2
  --enable-libopenmpt
  --enable-amf
```
