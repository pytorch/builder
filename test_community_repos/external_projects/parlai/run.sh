#!/bin/bash -xe

yes | pip install torchtext


BASEDIR=$(dirname $0)
pushd $BASEDIR


git clone https://github.com/facebookresearch/ParlAI.git
pushd ParlAI


python setup.py develop
#python examples/display_data.py -t squad
python examples/eval_model.py -m ir_baseline -t personachat -dt valid
python examples/train_model.py -t personachat -m transformer/ranker -mf /tmp/model_tr6 --n-layers 1 --embedding-size 300 --ffn-size 600 --n-heads 4 --num-epochs 2 -veps 0.25 -bs 64 -lr 0.001 --dropout 0.1 --embedding-type fasttext_cc --candidates batch


popd
rm -rf ParlAI
popd

