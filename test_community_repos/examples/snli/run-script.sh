pushd examples/snli
python train.py --epochs 1
RETURN_CODE=$?
popd
exit $RETURN_CODE

