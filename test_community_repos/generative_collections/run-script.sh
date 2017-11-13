set -e

cp ../__run.py ./

declare -a models_to_test=("GAN" "WGAN_GP" "EBGAN" "BEGAN")

for model in "${models_to_test[@]}"
do
  python __run.py --dataset mnist --gan_type "$model" --epoch 1 --batch_size 128
done

