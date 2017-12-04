#!/bin/bash
set -e

yum install -y -q wget

export MV=3
wget --quiet https://repo.continuum.io/miniconda/Miniconda$MV-latest-Linux-x86_64.sh && \
    chmod +x Miniconda$MV-latest-Linux-x86_64.sh && \
    ./Miniconda$MV-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda$MV-latest-Linux-x86_64.sh

export PATH="/opt/conda/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/conda"

