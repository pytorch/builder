set -e

python train.p --nEpochs 1
sleep 1 # time buffer for plot subprocess to finish. if it needs more time, just let it error.

