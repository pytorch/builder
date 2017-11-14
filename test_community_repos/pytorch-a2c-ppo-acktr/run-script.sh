set -e

pushd pytorch-a2c-ppo-acktr
python -m visdom.server &
python main.py --env-name "PongNoFrameskip-v4" --num-frames 100000
python main.py --env-name "PongNoFrameskip-v4" --algo ppo --use-gae --num-processes 8 --num-steps 256 --vis-interval 1 --log-interval 1 --num-frames 100000
python main.py --env-name "PongNoFrameskip-v4" --algo acktr --num-processes 32 --num-steps 20 --num-frames 100000
popd
