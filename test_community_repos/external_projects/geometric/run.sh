#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone git@github.com:rusty1s/pytorch_geometric.git
pushd pytorch_geometric


python setup.py test


popd
rm -rf pytorch_geometric
popd

