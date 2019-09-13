#!/bin/bash -xe


yes | pip install dominate


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/NVIDIA/pix2pixHD.git
pushd pix2pixHD


# Testing guidance obtained from here: https://github.com/NVIDIA/pix2pixHD#testing

# Download dataset
# TODO: Hosted on Google Drive as latest_net_G.pth; need somewhere programmatically accessible

bash ./scripts/test_1024p.sh


popd
rm -rf pix2pixHD
popd

