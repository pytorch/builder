set -e

pushd denoising
./create.py
./main.py --nEpoch 1 optnet --learnD --Dpenalty 0.1
sleep 2 # time buffer for plot subprocess to finish. if it needs more time, just let it error.
popd

