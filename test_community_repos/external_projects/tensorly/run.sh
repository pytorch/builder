#!/bin/bash -xe

yes | pip install git+https://github.com/tensorly/tensorly
yes | pip install pytest-xdist
yes | pip install nose

TMPDIR=$RANDOM
mkdir /tmp/$TMPDIR
git clone https://github.com/tensorly/tensorly /tmp/$TMPDIR
pushd /tmp/$TMPDIR
TENSORLY_BACKEND='pytorch' pytest -v tensorly
popd
rm -rf /tmp/$TMPDIR

