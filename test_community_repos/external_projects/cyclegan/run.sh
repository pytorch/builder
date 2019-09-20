#!/bin/bash -xe

# Hack to obtain "unzip" command
UNZIP_BINARY_PATH=$HOME/bin

mkdir $UNZIP_BINARY_PATH
ln -s ~/project/test_community_repos/examples/fast_neural_style/unzip.py $UNZIP_BINARY_PATH/unzip
chmod +x $UNZIP_BINARY_PATH/unzip
export PATH=$PATH:$UNZIP_BINARY_PATH

BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone https://github.com/junyanz/pytorch-CycleGAN-and-pix2pix.git
pushd pytorch-CycleGAN-and-pix2pix
../download_data.sh
../install-deps.sh
../run-script.sh
popd
rm -rf pytorch-CycleGAN-and-pix2pix
popd

# Clean up hack
rm -r $UNZIP_BINARY_PATH
