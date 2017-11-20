BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone --recursive https://github.com/Cadene/vqa.pytorch.git
pushd vqa.pytorch
../download_data.sh
../install-deps.sh
../run-script.sh
popd
rm -rf vqa.pytorch
popd

