#!/bin/bash

set -ex

OPENSSL=openssl-1.1.1k

wget -q -O ${OPENSSL}.tar.gz https://www.openssl.org/source/${OPENSSL}.tar.gz
tar xf ${OPENSSL}.tar.gz
cd ${OPENSSL}
./config -d '-Wl,--enable-new-dtags,-rpath,$(LIBRPATH)'
make install_sw # Only install the OpenSSL software components.
cd ..
rm -rf ${OPENSSL}
