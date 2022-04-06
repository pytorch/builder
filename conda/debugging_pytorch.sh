# builds inside docker image for debugging
# also see setup_ccache.sh

# copied from pytorch-0.4.1/build.sh
export TORCH_CUDA_ARCH_LIST="3.5;5.0+PTX;6.0;6.1;7.0"
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export NCCL_ROOT_DIR=/usr/local/cuda
export TH_BINARY_BUILD=1
export USE_STATIC_CUDNN=1
export USE_STATIC_NCCL=1
export ATEN_STATIC_CUDA=1
export USE_CUDA_STATIC_LINK=1

. ./switch_cuda_version.sh 9.0


conda install -y cmake numpy=1.17 setuptools pyyaml cffi mkl=2018 mkl-include typing_extension ninja magma-cuda80 -c pytorch

export CMAKE_PREFIX_PATH="$(dirname $(which conda))/../"
git clone https://github.com/pytorch/pytorch -b nightly2 --recursive
cd pytorch
python setup.py install
