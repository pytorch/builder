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
yum -y install epel-release
yum -y install less zstd

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
# Exec libglfortran.a hack
#
# libgfortran.a from quay.io/pypa/manylinux2014_aarch64 was not compiled with -fPIC.
# This causes __stack_chk_guard@@GLIBC_2.17 on pytorch build. To solve, get
# ubuntu's libgfortran.a which was compiled with -fPIC
###############################################################################
cd ~/
curl -L -o ~/libgfortran-10-dev.deb http://ports.ubuntu.com/ubuntu-ports/pool/universe/g/gcc-10/libgfortran-10-dev_10.4.0-6ubuntu1_arm64.deb
ar x ~/libgfortran-10-dev.deb
tar --use-compress-program=unzstd -xvf data.tar.zst -C ~/
cp -f ~/usr/lib/gcc/aarch64-linux-gnu/10/libgfortran.a /opt/rh/devtoolset-10/root/usr/lib/gcc/aarch64-redhat-linux/10/

###############################################################################
# Run aarch64 builder python
###############################################################################
cd /
# adding safe directory for git as the permissions will be
# on the mounted pytorch repo
git config --global --add safe.directory /pytorch
python /builder/aarch64_linux/aarch64_wheel_ci_build.py --python-version ${PYTHON_VERSION} --enable-mkldnn
