#!/bin/bash
set -ex

# Expected to be run on a Docker image built from
# https://github.com/pytorch/builder/blob/master/conda/Dockerfile (or the
# manywheel equivalent)
# Upgrades the devtoolset from 3 to 7

# The gcc version should be 4.9.2 right now
echo "Initial gcc version is $(gcc --version)"

# Uninstall devtoolset-3
yum remove -y -q devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-gcc-gfortran devtoolset-3-binutils

# Install devtoolset-7
yum install -y -q devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran devtoolset-7-binutils

# Replace PATH and LD_LIBRARY_PATH to updated devtoolset
export PATH=$(echo $PATH | sed 's/devtoolset-3/devtoolset-7/g')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed 's/devtoolset-3/devtoolset-7/g')

# The gcc version should now be 7.3.1
echo "Final gcc version is $(gcc --version)"
