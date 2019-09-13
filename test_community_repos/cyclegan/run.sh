#!/bin/bash -xe

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
