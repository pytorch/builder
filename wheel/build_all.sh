#!/usr/bin/env bash
set -e

BUILD_VERSION=0.1.9
BUILD_NUMBER=2

if [[ "$OSTYPE" == "darwin"* ]]; then
    rm -rf whl
    mkdir -p whl

    # osx no CUDA builds
    ./build_wheel.sh 2 -1 $BUILD_VERSION $BUILD_NUMBER
    ./build_wheel.sh 3.5 -1 $BUILD_VERSION $BUILD_NUMBER
    ./build_wheel.sh 3.6 -1 $BUILD_VERSION $BUILD_NUMBER

    ls whl/ | xargs -I {} aws s3 cp whl/{} s3://pytorch/whl/ --acl public-read
else
    rm -rf whl
    mkdir -p whl/cu75
    mkdir -p whl/cu80

    ~/switch_cuda_version.sh 7.5

    ./build_wheel.sh 2 7.5 $BUILD_VERSION $BUILD_NUMBER
    ./build_wheel.sh 3.5 7.5 $BUILD_VERSION $BUILD_NUMBER
    ./build_wheel.sh 3.6 7.5 $BUILD_VERSION $BUILD_NUMBER

    ~/switch_cuda_version.sh 8.0

    ./build_wheel.sh 2 8.0 $BUILD_VERSION $BUILD_NUMBER
    ./build_wheel.sh 3.5 8.0 $BUILD_VERSION $BUILD_NUMBER
    ./build_wheel.sh 3.6 8.0 $BUILD_VERSION $BUILD_NUMBER

    ~/switch_cuda_version.sh 7.5 # restore version

    ls whl/cu75/ | xargs -I {} aws s3 cp whl/cu75/{} s3://pytorch/whl/cu75/ --acl public-read
    ls whl/cu80/ | xargs -I {} aws s3 cp whl/cu80/{} s3://pytorch/whl/cu80/ --acl public-read
fi
