#!/usr/bin/env bash

# This is mostly just a shim to manywheel/build.sh
# TODO: Make this a dedicated script to build just libtorch

set -ex

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUILD_PYTHONLESS=1 DESIRED_PYTHON="3.7" ${SCRIPTPATH}/../manywheel/build.sh
