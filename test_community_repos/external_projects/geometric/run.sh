#!/bin/bash -xe

# Install dependencies (see https://github.com/rusty1s/pytorch_geometric#installation)
pip install --verbose --no-cache-dir torch-scatter
pip install --verbose --no-cache-dir torch-sparse
pip install --verbose --no-cache-dir torch-cluster
pip install --verbose --no-cache-dir torch-spline-conv


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone git@github.com:rusty1s/pytorch_geometric.git
pushd pytorch_geometric


python setup.py test


popd
rm -rf pytorch_geometric
popd

