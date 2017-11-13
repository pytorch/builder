pushd examples/mnist
# smoke test
python main.py --epochs 1
RETURN_CODE=$?
popd
exit $RETURN_CODE

