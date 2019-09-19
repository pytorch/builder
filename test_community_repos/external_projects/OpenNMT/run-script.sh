set -e

python preprocess.py -train_src data/src-train.txt -train_tgt data/tgt-train.txt -valid_src data/src-val.txt -valid_tgt data/tgt-val.txt -save_data data/demo

python train.py -data data/demo -save_model demo-model -train_steps 1 -gpuid 0

python translate.py -model demo-model_*.pt -src data/src-test.txt -output pred.txt -replace_unk -verbose -gpu 0  -max_sent_length 10

