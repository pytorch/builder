#!/bin/bash -xe


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone git@github.com:fastai/fastai.git
pushd fastai

# See https://github.com/fastai/fastai#developer-install
tools/run-after-git-clone
pip install -e ".[dev]"



pytest tests


popd
rm -rf fastai
popd

