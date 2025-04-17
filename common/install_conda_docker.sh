#!/bin/bash
# Script used only in CD pipeline
set -ex
# Anaconda
# Latest anaconda is using openssl-3 which is incompatible with all currently published versions of git
# Which are using openssl-1.1.1, see https://anaconda.org/anaconda/git/files?version=2.40.1 for example
MINICONDA_URL=https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
wget -q $MINICONDA_URL
# NB: Manually invoke bash per https://github.com/conda/conda/issues/10431
bash $(basename "$MINICONDA_URL") -b -p /opt/conda
rm $(basename "$MINICONDA_URL")
export PATH=/opt/conda/bin:$PATH

# First specifically install Python 3.11 which is compatible with conda 23.5.2
conda install -y python=3.11

# Pin conda to 23.5.2 as it's the last one compatible with openssl-1.1.1
conda install -y conda=23.5.2 conda-build anaconda-client git ninja

# The cmake version here needs to match with the minimum version of cmake
# supported by PyTorch (3.18). There is only 3.18.2 on anaconda
/opt/conda/bin/pip3 install cmake==3.18.2
conda remove -y --force patchelf
