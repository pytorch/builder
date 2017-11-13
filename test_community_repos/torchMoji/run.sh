BASEDIR=$(dirname $0)
git clone https://github.com/huggingface/torchMoji.git
pushd torchMoji
../download_data.sh
../install-deps.sh
../run-script.sh
popd
rm -rf torchMoji

