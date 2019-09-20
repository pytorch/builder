#!/bin/bash -xe

yes | pip install block nose scipy torch


TMPDIR=$RANDOM
mkdir /tmp/$TMPDIR
git clone https://github.com/bamos/block /tmp/$TMPDIR
pushd /tmp/$TMPDIR
nosetests test.py
popd
rm -rf /tmp/$TMPDIR
