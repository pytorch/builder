BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone https://github.com/ikostrikov/pytorch-a2c-ppo-acktr.git
./download-data.sh
./install-deps.sh
./run-script.sh
RETURN=$?
rm -rf pytorch-a2c-ppo-acktr
popd
exit $RETURN

