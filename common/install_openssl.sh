#!/bin/bash

set -ex

OPENSSL=OpenSSL_1_1_1k

wget -q -O ${OPENSSL}.tar.gz https://github.com/openssl/openssl/archive/${OPENSSL}.tar.gz
tar xf ${OPENSSL}.tar.gz
cd openssl-${OPENSSL}
./config -d '-Wl,--enable-new-dtags,-rpath,$(LIBRPATH)'
make install
cd ..
rm -rf openssl-${OPENSSL}

