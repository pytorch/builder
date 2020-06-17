## Building conda binaries

- Change the BUILD_VERSION and BUILD_NUMBER variables in build_pytorch.sh as appropriate
- If pytorch-$BUILD_VERSION folder doesn't exist, copy over the last version and change the meta.yaml if necessary (if tests change etc.)
  - `cp -r pytorch-0.1.3 pytorch-$BUILD_VERSION`
  - `git add pytorch-$BUILD_VERSION`
- Run `./build_pytorch.sh` on an OSX machine and a Linux machine

## build base docker image

```
cd ..
nvidia-docker build -t soumith/conda-cuda -f conda/Dockerfile .
docker push soumith/conda-cuda
```

## building pytorch / torchvision etc.

```
docker run -it --ipc=host --rm -v $(pwd):/remote pytorch/conda-cuda bash

cd remote/conda

# versioned
export PYTORCH_FINAL_PACKAGE_DIR="/remote"
export TORCH_CONDA_BUILD_FOLDER=pytorch-1.1.0
export PYTORCH_REPO=pytorch
export PYTORCH_BRANCH=v1.1.0
./build_pytorch.sh 100 1.1.0 1 # cuda 10.0 pytorch 1.0.1 build_number 1

# nightly
export PYTORCH_FINAL_PACKAGE_DIR="/remote"
export TORCH_CONDA_BUILD_FOLDER=pytorch-nightly
export PYTORCH_REPO=pytorch
export PYTORCH_BRANCH=master
./build_pytorch.sh 100 nightly 1 # cuda 10.0 pytorch 1.0.1 build_number 1

```


## building magma

> MOVED TO [magma/README.md](../magma/README.md)
