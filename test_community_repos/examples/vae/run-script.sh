pushd examples/vae
python main.py --epochs 1
RETURN_CODE=$?
popd
exit $RETURN_CODE

