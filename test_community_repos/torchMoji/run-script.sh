set -e

pushd tests
nosetests -v -a '!slow'
popd

