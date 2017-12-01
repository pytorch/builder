#!/usr/bin/env bash
set -e

BUILD_VERSION=0.3.0
BUILD_NUMBER=3

if [[ "$OSTYPE" == "darwin"* ]]; then
    rm -rf whl
    mkdir -p whl

    # osx no CUDA builds
    ./build_wheel.sh 2   $BUILD_VERSION $BUILD_NUMBER
    ./build_wheel.sh 3.5 $BUILD_VERSION $BUILD_NUMBER
    ./build_wheel.sh 3.6 $BUILD_VERSION $BUILD_NUMBER

    ls whl/ | xargs -I {} aws s3 cp whl/{} s3://pytorch/whl/ --acl public-read
fi
