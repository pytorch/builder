set -ex

BASEDIR=$(dirname $0)
pushd $BASEDIR
git clone https://github.com/facebookresearch/DrQA.git
./download-data.sh
./install-deps.sh
./run-script.sh
rm -rf DrQA
popd

