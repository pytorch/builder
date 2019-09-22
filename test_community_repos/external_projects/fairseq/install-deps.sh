#!/bin/bash -xe

#pip install -r requirements.txt
python setup.py build


# Potential workaround for probem on macos:
#    fastBPE/fastBPE.hpp:17:10: fatal error: 'thread' file not found
# See: https://github.com/facebookresearch/XLM/issues/105
CFLAGS='-stdlib=libc++' python setup.py develop
#python setup.py develop

