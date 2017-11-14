BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone https://github.com/locuslab/qpth
./download-data.sh
./install-deps.sh
./run-script.sh
RETURN=$?
rm -rf qpth
popd
exit $RETURN

