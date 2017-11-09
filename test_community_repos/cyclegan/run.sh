BASEDIR=$(dirname $0)
git clone https://github.com/junyanz/pytorch-CycleGAN-and-pix2pix.git
pushd pytorch-CycleGAN-and-pix2pix
../download_data.sh
../install-deps.sh
../run-script.sh

