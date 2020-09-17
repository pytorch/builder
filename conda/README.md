## Building conda binaries

- Change the BUILD_VERSION and BUILD_NUMBER variables in build_pytorch.sh as appropriate
- If pytorch-$BUILD_VERSION folder doesn't exist, copy over the last version and change the meta.yaml if necessary (if tests change etc.)
  - `cp -r pytorch-0.1.3 pytorch-$BUILD_VERSION`
  - `git add pytorch-$BUILD_VERSION`
- Run `./build_pytorch.sh` on an OSX machine and a Linux machine

## build base docker image

```sh
cd ..
docker build -t soumith/conda-cuda -f conda/Dockerfile .
docker push soumith/conda-cuda
```

## building pytorch / torchvision etc.

```sh
# building pytorch
docker run --rm -it \
    -e PACKAGE_TYPE=conda \
    -e DESIRED_CUDA=cu92 \
    -e DESIRED_PYTHON=3.8 \
    -e PYTORCH_BUILD_VERSION=1.5.0 \
    -e PYTORCH_BUILD_NUMBER=1 \
    -e OVERRIDE_PACKAGE_VERSION=1.5.0
    -e TORCH_CONDA_BUILD_FOLDER=pytorch-nightly \
    -v /path/to/pytorch:/pytorch \
    -v /path/to/builder:/builder \
    -v "$(pwd):/final_pkgs" \
    -u "$(id -u):$(id -g)"  \
    pytorch/conda-cuda \
    /builder/conda/build_pytorch.sh
```


## building magma

> MOVED TO [magma/README.md](../magma/README.md)
