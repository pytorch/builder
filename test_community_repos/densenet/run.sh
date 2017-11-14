BASEDIR=$(dirname $0)
git clone https://github.com/bamos/densenet.pytorch.git
pushd densenet.pytorch
../install-deps.sh
../run-script.sh
popd
rm -rf densenet.pytorch

