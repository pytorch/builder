#!/bin/bash

set -ex

OPENSSL=openssl-3.2.1

yum install -y perl-IPC-Cmd

wget -q -O ${OPENSSL}.tar.gz "https://www.openssl.org/source/${OPENSSL}.tar.gz"
tar xf "${OPENSSL}.tar.gz"
cd "${OPENSSL}"
./config --prefix=/opt/openssl -d '-Wl,--enable-new-dtags,-rpath,$(LIBRPATH)'
make -j $(nproc)
make install
ldconfig
cd ..
rm -rf "${OPENSSL}"
