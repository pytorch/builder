# Base docker image for cross-compilling FFmpeg (LGPL) for Windows
FROM pytorch/manylinux-cuda101
COPY . /ffmpeg-build-src
WORKDIR /ffmpeg-build-src

# Install required system libraries
RUN yum install epel-release
RUN yum install -y \
    autoconf \
    automake \
    bash \
    bison \
    bzip2 \
    flex \
    gcc-c++ \
    gdk-pixbuf2-devel \
    gettext \
    git \
    gperf \
    intltool \
    libtool \
    lzip \
    make \
    openssl \
    openssl-devel \
    p7zip \
    patch \
    perl \
    python \
    ruby \
    sed \
    unzip \
    wget \
    xz \
    nano

# Update automake to 1.15
RUN wget https://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz
RUN tar -xzvf automake-1.15.tar.gz
RUN cd automake-1.15.tar.gz && ./configure && make && make install

# Create MXE environment and install packages
RUN bash build_mxe.sh

# Compile and install OpenH264
RUN bash build_openh264.sh
