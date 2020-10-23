#!/bin/bash
set -ex

TORCH_VER=$1
SETUP_FILE="setup.py"
REPLACE_KEYWORD="{{GENERATE_TORCH_PKG_VER}}"

mkdir torch
cp $SETUP_FILE torch/
cd torch
sed -i "s/$REPLACE_KEYWORD/$TORCH_VER/g" $SETUP_FILE
python $SETUP_FILE sdist

echo "Generate package under torch/dist"