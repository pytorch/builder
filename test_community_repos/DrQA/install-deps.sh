set -ex

pushd DrQA

# CoreNLP needs java. Verify we have it
java -version

pip install -r requirements.txt
python setup.py develop

echo -e "\nN" | ./install_corenlp.sh
export CLASSPATH=$CLASSPATH:data/corenlp/*

popd

