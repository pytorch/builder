#!/bin/bash
set -ex

COMMAND_TO_WRAP=$1

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. "$script_dir/pkg_helpers.bash"

export BUILD_TYPE=wheel
setup_env 0.5.0
setup_wheel_python
pip_install numpy pyyaml future ninja
setup_pip_pytorch_version
#python setup.py clean
#IS_WHEEL=1 python setup.py bdist_wheel

$COMMAND_TO_WRAP
