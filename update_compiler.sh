#!/bin/bash
set -ex

# NOTE: This script is called by default on all nightlies.

# Expected to be run on a Docker image built from
# https://github.com/pytorch/builder/blob/master/conda/Dockerfile (or the
# manywheel equivalent)
# Updates the compiler toolchain from devtoolset 3 to 7

# ~~~
# Why does this file exist? Why not just update the compiler on the base docker
# images?
#
# Answer: Yes we should just update the compiler to devtoolset7 on all the CentOS
# base docker images. There's no reason to keep around devtoolset3 because it's
# not used anymore.
#
# We use devtoolset7 instead of devtoolset3 because devtoolset7 /is/ able to
# build with avx512 instructions, which are needed for fbgemm to get good
# performance.
#
# Note that devtoolset7 still *cannot* build with the new gcc ABI
# (see https://bugzilla.redhat.com/show_bug.cgi?id=1546704). Instead, we use
# Ubuntu 16.04 + gcc 5.4 to build with the new gcc ABI, using an Ubuntu 16.04
# base docker image.
# For details, see NOTE [ Building libtorch with old vs. new gcc ABI ].

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
