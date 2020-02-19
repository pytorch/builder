#!/bin/bash

set -ex

# MKL
mkdir -p /opt/intel/lib
pushd /tmp
curl -fsSL https://anaconda.org/intel/mkl-static/2019.5/download/linux-64/mkl-static-2019.5-intel_281.tar.bz2 | tar xjv
mv lib/* /opt/intel/lib/
curl -fsSL https://anaconda.org/intel/mkl-include/2019.5/download/linux-64/mkl-include-2019.5-intel_281.tar.bz2 | tar xjv
mv include /opt/intel/
