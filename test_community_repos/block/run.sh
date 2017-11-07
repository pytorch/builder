yes | pip install block
yes | pip install nose

TMPDIR=$RANDOM
mkdir /tmp/$TMPDIR
git clone https://github.com/bamos/block /tmp/$TMPDIR
pushd /tmp/$TMPDIR
nosetests test.py
popd
rm -rf /tmp/$TMPDIR
