#!/bin/bash
set -ex

# Expected to be run on a Docker image built from
# https://github.com/pytorch/builder/blob/master/conda/Dockerfile (or the
# manywheel equivalent)
# Updates the compiler toolchain from devtoolset 3 to 7

# ~~~
# Why does this file exist? Why not just update the compiler on the base docker
# images?
#
# So, all the nightlies used to be built on devtoolset3 with the old gcc ABI.
# These packages worked well for most people, but could not be linked against
# by client c++ libraries that were compiled using the new gcc ABI. Since both
# gcc ABIs are still common in the wild, we should be able to support both
# ABIs. Hence, we need a script to alter the compiler on the root docker images
# to configure which ABI we want to build with.
#
# So then this script was written to change from devtoolset3 to devtoolset7. It
# turns out that this doesn't actually fix the problem, since devtoolset7 is
# incapable of building with the new gcc ABI. BUT, devtoolset7 /is/ able to
# build with avx512 instructions, which are needed for fbgemm to get good
# performance. So now this script is called by default on all nightlies.
#
# But we still don't have the new gcc ABI. So what should happen next is
# - Upgrade the compiler on all the base docker images to be devtoolset7.
#   There's no reason to keep around devtoolset3. It will never be used.
# - Alter this script to install another compiler toolchain, not a devtoolset#,
#   which can build with the new gcc ABI. Then use this script as intended, in
#   a parallel suite of new-gcc-ABI nightlies.
#
# When this script is finally changed to build with the new gcc ABI, then we'll
# need to set this variable manually because
# https://github.com/pytorch/pytorch/blob/master/torch/abi-check.cpp sets the
# ABI to 0 by default. 
# ``` export _GLIBCXX_USE_CXX11_ABI=1 ```
# Note that this probably needs to get set in the .circleci infra that's
# running this, since env variables set in this file are probably discarded.
# ~~~

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
