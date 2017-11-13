BASEDIR=$(dirname $0)
git clone https://github.com/znxlwm/pytorch-generative-model-collections.git
pushd pytorch-generative-model-collections
../run-script.sh
popd
rm -rf pytorch-generative-model-collections

