#!/bin/bash
set -eux -o pipefail

GPU_ARCH_VERSION=${GPU_ARCH_VERSION:-}

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPTPATH/aarch64_ci_setup.sh

tagged_version() {
  GIT_DESCRIBE="git --git-dir /pytorch/.git describe --tags --match v[0-9]*.[0-9]*.[0-9]*"
  if ${GIT_DESCRIBE} --exact >/dev/null; then
    ${GIT_DESCRIBE}
  else
    return 1
  fi
}

if tagged_version >/dev/null; then
  export OVERRIDE_PACKAGE_VERSION="$(tagged_version | sed -e 's/^v//' -e 's/-.*$//')"
fi

###############################################################################
# Run aarch64 builder python
###############################################################################
cd /
# adding safe directory for git as the permissions will be
# on the mounted pytorch repo
git config --global --add safe.directory /pytorch
pip install -r /pytorch/requirements.txt
pip install auditwheel
if [ -n "$GPU_ARCH_VERSION" ]; then
    echo "BASE_CUDA_VERSION is set to: $GPU_ARCH_VERSION"
    python /builder/aarch64_linux/aarch64_wheel_ci_build.py --enable-mkldnn --enable-cuda
else
    echo "BASE_CUDA_VERSION is not set."
    python /builder/aarch64_linux/aarch64_wheel_ci_build.py --enable-mkldnn
fi