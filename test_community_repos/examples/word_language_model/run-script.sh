pushd examples/word_language_model
# smoke tests
python main.py --cuda --epochs 1
python main.py --cuda --epochs 1 --tied
RETURN_CODE=$?
popd
exit $RETURN_CODE

