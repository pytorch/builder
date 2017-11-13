BASEDIR=$(dirname $0)
git clone https://github.com/facebookresearch/fairseq-py.git
pushd fairseq-py
../download_data.sh
../install-deps.sh
../run-script.sh
popd
rm -rf fairseq-py

