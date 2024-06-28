#!/bin/bash

set -ex

# MKL
MKL_VERSION=2022.2.1

mkdir -p /opt/intel/
pushd /tmp

python3 -mpip download -d . mkl-static==${MKL_VERSION}
unzip mkl_static-${MKL_VERSION}-py2.py3-none-manylinux1_x86_64.whl
unzip mkl_include-${MKL_VERSION}-py2.py3-none-manylinux1_x86_64.whl
mv mkl_static-${MKL_VERSION}.data/data/lib /opt/intel/
mv mkl_include-${MKL_VERSION}.data/data/include/ /opt/intel/
