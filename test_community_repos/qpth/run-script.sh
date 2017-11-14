pushd qpth

# Manually remove test_sparse_forward and test_sparse_backward.
# They rely on this unmerged pr: https://github.com/pytorch/pytorch/pull/1716
sed -i -e 's/def test_sparse_/@npt.decorators.skipif(True)\ndef test_sparse_/g' test.py

# Run tests
nosetests -v -d test.py 
RETURN_CODE=$?
popd
exit $RETURN_CODE

