pushd examples/dcgan
# smoke test
python main.py --dataset fake --dataroot . --cuda --niter 1
RETURN_CODE=$?
popd
exit $RETURN_CODE

