pushd examples/mnist_hogwild
# smoke tests
python main.py --epochs 1
RETURN_CODE=$?
popd
exit $RETURN_CODE

