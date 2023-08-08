#!/bin/bash
set -eux -o pipefail

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPTPATH/aarch64_ci_setup.sh

###############################################################################
# Run aarch64 builder python
###############################################################################
cd /
# adding safe directory for git as the permissions will be
# on the mounted pytorch repo
git config --global --add safe.directory /pytorch
pip install -r /pytorch/requirements.txt
pip install auditwheel
python /builder/aarch64_linux/aarch64_wheel_ci_build.py --enable-mkldnn
