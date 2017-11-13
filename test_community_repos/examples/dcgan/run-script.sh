pushd examples/dcgan
# smoke test
python main.py --dataset fake --dataroot . --cuda --niter 100
RETURN_CODE=$?
popd
exit $RETURN_CODE

