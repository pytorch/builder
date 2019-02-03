## Building conda binaries

- Change the BUILD_VERSION and BUILD_NUMBER variables in build_pytorch.sh as appropriate
- If pytorch-$BUILD_VERSION folder doesn't exist, copy over the last version and change the meta.yaml if necessary (if tests change etc.)
  - `cp -r pytorch-0.1.3 pytorch-$BUILD_VERSION`
  - `git add pytorch-$BUILD_VERSION`
- Run `./build_pytorch.sh` on an OSX machine and a Linux machine

## build base docker image

```
nvidia-docker build -t soumith/conda-cuda -f Dockerfile .
docker push soumith/conda-cuda
```

## building pytorch / torchvision etc.

```
nvidia-docker run -it --ipc=host --rm -v $(pwd):/remote soumith/conda-cuda bash
cd remote/conda
export PYTORCH_FINAL_PACKAGE_DIR="/remote"
export TORCH_CONDA_BUILD_FOLDER=pytorch-1.0.1
export PYTORCH_REPO=pytorch
export PYTORCH_BRANCH=v1.0.1
./build_pytorch.sh 100 1.0.1 1 # cuda 10.0 pytorch 1.0.1 build_number 1
./build_vision.sh
```


## building magma-cuda91

```
nvidia-docker run -it --ipc=host --rm -v $(pwd):/remote soumith/conda-cuda bash
yum install -y yum-utils centos-release-scl
yum-config-manager --enable rhel-server-rhscl-7-rpms
yum install -y devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-gcc-gfortran devtoolset-3-binutils
export PATH=/opt/rh/devtoolset-3/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/devtoolset-3/root/usr/lib64:/opt/rh/devtoolset-3/root/usr/lib:$LD_LIBRARY_PATH
git clone https://github.com/pytorch/builder
cd builder/conda
conda install -y conda-build
. ./switch_cuda_version.sh 10.0
conda build magma-cuda100-2.5.0
```
