pushd examples/super_resolution
python main.py --upscale_factor 3 --batchSize 4 --testBatchSize 100 --nEpochs 1 --lr 0.001
RETURN_CODE=$?
popd
exit $RETURN_CODE

