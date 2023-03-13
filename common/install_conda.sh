#!/bin/bash

set -ex

# Anaconda
wget -q https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x  Miniconda3-latest-Linux-x86_64.sh
# NB: Manually invoke bash per https://github.com/conda/conda/issues/10431
bash ./Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda
rm Miniconda3-latest-Linux-x86_64.sh
export PATH=/opt/conda/bin:$PATH
# The cmake version here needs to match with the minimum version of cmake
# supported by PyTorch (3.18). There is only 3.18.2 on anaconda
conda install -y conda-build anaconda-client git ninja cmake=3.18.2
conda remove -y --force patchelf
