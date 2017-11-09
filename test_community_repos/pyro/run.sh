yes | pip install pytest-xdist
yes | pip install sphinx
yes | pip install sphinx_rtd_theme

TMPDIR=$RANDOM
mkdir /tmp/$TMPDIR
git clone https://github.com/uber/pyro /tmp/$TMPDIR
pushd /tmp/$TMPDIR
yes | pip install .
make test
make test-cuda
make integration-test
make test-examples
make test-tutorials
popd
rm -rf /tmp/$TMPDIR

