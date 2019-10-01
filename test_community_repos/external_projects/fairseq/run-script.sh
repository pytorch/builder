#!/bin/bash -xe

TEXT=examples/translation/iwslt14.tokenized.de-en
python preprocess.py --source-lang de --target-lang en \
   --trainpref $TEXT/train --validpref $TEXT/valid --testpref $TEXT/test \
   --destdir data-bin/iwslt14.tokenized.de-en

mkdir -p checkpoints/fconv
CUDA_VISIBLE_DEVICES=0 python train.py data-bin/iwslt14.tokenized.de-en \
    --lr 0.25 --clip-norm 0.1 --dropout 0.2 --max-tokens 4000 --max-epoch 1 \
    --arch fconv_iwslt_de_en --save-dir checkpoints/fconv

python generate.py data-bin/iwslt14.tokenized.de-en \
  --path checkpoints/fconv/checkpoint_best.pt \
  --batch-size 128 --beam 5

