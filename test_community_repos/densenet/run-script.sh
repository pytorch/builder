set -e

pushd densenet.pytorch

python train.py --nEpochs 1
sleep 1 # time buffer for plot subprocess to finish. if it needs more time, just let it error.

popd
