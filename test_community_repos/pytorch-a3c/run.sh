BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone https://github.com/ikostrikov/pytorch-a3c.git
./download-data.sh
./install-deps.sh
./run-script.sh
RETURN=$?
rm -rf pytorch-a3c
popd
exit $RETURN

