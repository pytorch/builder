set -e

python train.py --vqa_trainsplit train --path_opt options/vqa/mutan_att_trainval.yaml --epoch 2
sleep 5 # time buffer for eval subprocess to finish. if it needs more time, just let it error.

