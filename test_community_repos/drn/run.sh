BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone https://github.com/fyu/drn.git
./download-data.sh
./install-deps.sh
./run-script.sh
RETURN=$?
rm -rf drn
popd
exit $RETURN

