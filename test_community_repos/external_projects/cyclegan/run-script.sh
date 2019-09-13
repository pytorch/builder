set -e

if [ $CU_VERSION == 'cpu' ]
then
    FORCE_CPU_ARG="--gpu_ids -1"
fi


python -m visdom.server &
trap 'kill $(jobs -p)' EXIT
python train.py $FORCE_CPU_ARG --dataroot ./datasets/maps --name maps_cyclegan --model cycle_gan --no_dropout --niter 1 --niter_decay 0 --no_html --max_dataset_size 400 --batch_size 1 --print_freq 500 --display_freq 500
python train.py $FORCE_CPU_ARG --dataroot ./datasets/facades --name facades_pix2pix --model pix2pix --which_model_netG unet_256 --which_direction BtoA --lambda_A 100 --dataset_mode aligned --no_lsgan --norm batch --pool_size 0 --niter 1 --niter_decay 0 --no_html --max_dataset_size 400 --batch_size 1 --print_freq 500 --display_freq 500

