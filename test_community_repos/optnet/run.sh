BASEDIR=$(dirname $0)
git clone https://github.com/locuslab/optnet.git
pushd optnet
../install-deps.sh
../run-script.sh
popd
rm -rf optnet

