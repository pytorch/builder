#!/bin/bash

set -ex

# Anaconda
wget -q https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x  Miniconda3-latest-Linux-x86_64.sh
# NB: Manually invoke bash per https://github.com/conda/conda/issues/10431
bash ./Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda
rm Miniconda3-latest-Linux-x86_64.sh
export PATH=/opt/conda/bin:$PATH
conda install -y conda-build anaconda-client git ninja cmake=3.22.1
# The cmake version here needs to match with the minimum version of cmake
# supported by PyTorch, conda doesn't have cmake 3.18.4 anymore while
# system cmake is too old (3.17.5). So we get it from pip like manywheel
conda run python3 -mpip install cmake==3.18.4
conda remove -y --force patchelf
