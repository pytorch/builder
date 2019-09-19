#!/bin/bash -xe


if [ $CU_VERSION != 'cpu' ]
then
    GPU_ARGS="-world_size 1 -gpu_ranks 0"
fi


python preprocess.py -train_src data/src-train.txt -train_tgt data/tgt-train.txt -valid_src data/src-val.txt -valid_tgt data/tgt-val.txt -save_data data/demo

python train.py -data data/demo -save_model demo-model -train_steps 1 $GPU_ARGS

python translate.py -model demo-model_*.pt -src data/src-test.txt -output pred.txt -replace_unk -verbose -gpu 0 -max_length 10

