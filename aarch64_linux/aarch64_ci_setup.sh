#!/bin/bash
set -eux -o pipefail

# This script is used to prepare the Docker container for aarch64_ci_wheel_build.py python script
# as we need to install conda and setup the python version for the build.

CONDA_PYTHON_EXE=/opt/conda/bin/python
CONDA_EXE=/opt/conda/bin/conda
PATH=/opt/conda/bin:$PATH
LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH

###############################################################################
# Install conda
# disable SSL_verify due to getting "Could not find a suitable TLS CA certificate bundle, invalid path"
# when using Python version, less than the conda latest
###############################################################################
echo 'Installing conda-forge'
curl -L -o /mambaforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh
chmod +x /mambaforge.sh
/mambaforge.sh -b -p /opt/conda
rm /mambaforge.sh
/opt/conda/bin/conda config --set ssl_verify False
/opt/conda/bin/conda install -y -c conda-forge python=${DESIRED_PYTHON} numpy pyyaml setuptools patchelf pygit2 openblas ninja scons
python --version
conda --version
