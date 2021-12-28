#!/usr/bin/env bash

# This is mostly just a shim to manywheel/build.sh
# TODO: Make this a dedicated script to build just libtorch

set -ex

TOPDIR=$(git rev-parse --show-toplevel)

BUILD_PYTHONLESS=1 ${TOPDIR}/manywheel/build.sh
