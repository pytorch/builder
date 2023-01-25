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
/opt/conda/bin/conda install -y -c conda-forge python=${PYTHON_VERSION} numpy pyyaml setuptools
export CONDA_PYTHON_EXE='/opt/conda/bin/python'
export CONDA_EXE='/opt/conda/bin/conda'
export PATH='/opt/conda/bin:$PATH'
python --version
conda --version

###############################################################################
# Run aarch64 builder python
###############################################################################
cd /
python /builder/aarch64_wheel_ci_build.py --python-version ${PYTHON_VERSION} --enable-mkldnn
