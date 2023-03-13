#!/bin/bash

set -ex

# Anaconda
wget -q https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x  Miniconda3-latest-Linux-x86_64.sh
# NB: Manually invoke bash per https://github.com/conda/conda/issues/10431
bash ./Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda
rm Miniconda3-latest-Linux-x86_64.sh
export PATH=/opt/conda/bin:$PATH
conda install -y conda-build anaconda-client git ninja
conda remove -y --force patchelf
