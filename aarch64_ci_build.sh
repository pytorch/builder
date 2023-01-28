#!/bin/bash
set -eux -o pipefail

# This script is used to prepare the Docker container for aarch64_ci_wheel_build.py python script
# as we need to install conda and setup the python version for the build.

CONDA_PYTHON_EXE=/opt/conda/bin/python
CONDA_EXE=/opt/conda/bin/conda
PATH=/opt/conda/bin:$PATH

###############################################################################
# Install OS dependent packages
###############################################################################
yum -y install less

###############################################################################
# Install conda
###############################################################################
echo 'Installing conda-forge'
curl -L -o /mambaforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh
chmod +x /mambaforge.sh
/mambaforge.sh -b -p /opt/conda
rm /mambaforge.sh
/opt/conda/bin/conda install -y -c conda-forge python=${PYTHON_VERSION} numpy pyyaml setuptools patchelf
python --version
conda --version

###############################################################################
# Run aarch64 builder python
###############################################################################
cd /
# adding safe directory for git as the permissions will be
# on the mounted pytorch repo
git config --global --add safe.directory /pytorch
python /builder/aarch64_wheel_ci_build.py --python-version ${PYTHON_VERSION} --enable-mkldnn
