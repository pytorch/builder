#!/bin/bash -xe

yes | pip install pytest-xdist
# pip install thinc breaks depending on gcc version  
yes | conda install thinc

TMPDIR=$RANDOM
mkdir /tmp/$TMPDIR
git clone https://github.com/allenai/allennlp /tmp/$TMPDIR
pushd /tmp/$TMPDIR

pip install -r requirements.txt

pytest -v
popd
rm -rf /tmp/$TMPDIR

