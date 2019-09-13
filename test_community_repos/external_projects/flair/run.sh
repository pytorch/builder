#!/bin/bash -xe

yes | pip install pytest-xdist pipenv


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/zalandoresearch/flair.git
pushd flair


# Testing guidance taken from here: https://github.com/zalandoresearch/flair#running-unit-tests-locally
pipenv install --dev && pipenv shell
pytest --runintegration tests/


popd
rm -rf flair
popd

