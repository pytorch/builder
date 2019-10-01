#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/BorealisAI/advertorch.git
pushd advertorch

python setup.py install
python advertorch_examples/tutorial_train_mnist.py

popd
rm -rf advertorch
popd

