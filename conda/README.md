## Building conda binaries

- Change the BUILD_VERSION and BUILD_NUMBER variables in build_all.sh as appropriate
- If pytorch-$BUILD_VERSION folder doesn't exist, copy over the last version and change the meta.yaml if necessary (if tests change etc.)
  - `cp -r pytorch-0.1.3 pytorch-$BUILD_VERSION`
  - `git add pytorch-$BUILD_VERSION`
- Run `./build_all.ash` on an OSX machine and a Linux machine


### TODO
- [x] Make sure you build against magma
- [x] Build and test on Linux + CUDA
- [ ] Build and test on OSX + CUDA
- [x] Check what happens when you build on Linux + CUDA on one machine and run the binary on another machine
  - [x] without cuda or a driver
  - [x] with a different GPU driver than the original
  - [x] with an insufficient driver version corresponding to the CUDA version


# build base docker image
```
nvidia-docker build -t soumith/conda-cuda -f Dockerfile .
docker push soumith/conda-cuda
```



# building magma-cuda90

```
nvidia-docker run -it --rm -v $(pwd):/remote soumith/conda-cuda bash
yum install -y yum-utils centos-release-scl
yum-config-manager --enable rhel-server-rhscl-7-rpms
yum install -y devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-gcc-gfortran devtoolset-3-binutils
export PATH=/opt/rh/devtoolset-3/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/devtoolset-3/root/usr/lib64:/opt/rh/devtoolset-3/root/usr/lib:$LD_LIBRARY_PATH
git clone https://github.com/pytorch/builder
cd builder/conda
conda install conda-build
conda build magma-cuda90-2.2.0
```
