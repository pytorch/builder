pushd DrQA

# prepare some sample data input
head -n 5 data/datasets/WikiMovies-test.txt > dataset.txt
python scripts/pipeline/predict.py dataset.txt
RETURN=$?
popd
exit $RETURN
