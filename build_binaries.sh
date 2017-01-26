#!/usr/bin/env bash
set -e

pushd wheel
./build_all.sh
popd

pushd conda
./build_all.sh
popd
