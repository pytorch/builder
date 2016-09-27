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
