#!/bin/bash
# designed/tested on ubuntu 16.04

sudo apt-get install -y python3 python3-dev python-virtualenv
virtualenv -p python3 env3
source env3/bin/activate
pip install -U pip
pip install -U setuptools
pip install -U wheel
pip install -r requirements.txt

