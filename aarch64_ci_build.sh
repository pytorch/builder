#!/bin/bash
set -eux -o pipefail

PYTHON_VERSION=3.10

###############################################################################
# Install conda
###############################################################################
echo 'Installing conda-forge'
curl -L -o ~/mambaforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh
chmod +x ~/mambaforge.sh
~/mambaforge.sh -b -p /opt/conda
rm ~/mambaforge.sh
/opt/conda/bin/conda install -c conda-forge python=${PYTHON_VERSION} numpy pyyaml setuptools
/opt/conda/bin/conda init bash
source ~/.bashrc

###############################################################################
# Run aarch64 builder python
###############################################################################
cd /
python /builder/aarch64_wheel_ci_build.py --python-version ${PYTHON_VERSION} --enable-mkldnn True
