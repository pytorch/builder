#!/bin/bash -xe

BASEDIR=$(dirname $0)
pushd $BASEDIR

yes | pip install matplotlib gym pandas tensorflow scikit-image

# The docker image doesn't come with these prebuilt
if [ -f /.dockerenv ]; then
    apt-get -qq update
    apt-get -qq -y install unzip
    apt-get -qq -y install wget
fi

git clone https://github.com/pytorch/tutorials.git

pushd tutorials

set -x -e

# for seq2seq_translation_tutorial
wget https://download.pytorch.org/tutorial/data.zip
yes | unzip data.zip

# The docker image can't display images
python ../run.py

popd
popd
