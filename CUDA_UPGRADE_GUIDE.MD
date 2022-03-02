# CUDA Upgrade Guide/Runbook

So you wanna upgrade PyTorch to support a new CUDA? Follow these steps in order! They are adapted from previous CUDA upgrade processes.

## 0. Before starting upgrade process

### A. Currently Supported CUDA and CUDNN Libraries
Here is the supported matrix for CUDA and CUDNN

| CUDA | CUDNN | additional details |
| --- | --- | --- |
| 10.2 | 7.6.5.32 | Needed for publishing CUDA enabled binaries to PyPi since CUDA 11.x binaries don’t meet the space requirements (<750MB) | 
| 11.3 | 8.2.0.53 | Stable CUDA Release |
| 11.5 | 8.3.2.44 | Latest CUDA Release |


### B. Check the package availability

Package availability to validate before starting upgrade process :

1) CUDA and CUDNN is available for Linux and Windows:
https://developer.download.nvidia.com/compute/cuda/11.5.0/local_installers/cuda_11.5.0_495.29.05_linux.run
https://developer.download.nvidia.com/compute/redist/cudnn/v8.3.2/local_installers/11.5/

2) CUDA is available on conda via nvidia chanell : https://anaconda.org/nvidia/cuda/files

3) CudaToolkit is availbale on conda via nvidia chanell : https://anaconda.org/nvidia/cudatoolkit/files

4) CUDA with CUDNN is available on Docker hub images : https://hub.docker.com/r/nvidia/cuda
   Following example is for cuda 11.5: https://gitlab.com/nvidia/container-images/cuda/-/tree/master/dist/11.5.1/ubuntu2004/runtime
   (Make sure cudnn folder is present: https://gitlab.com/nvidia/container-images/cuda/-/tree/master/dist/11.5.1/ubuntu2004/runtime/cudnn8)

5) Validate new driver availability: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html. Check following table: Table 3. CUDA Toolkit and Corresponding Driver Versions


## 1. Maintain Progress and Updates
Make an issue to track the progress, for example [#56721: Support 11.3](https://github.com/pytorch/pytorch/issues/56721). This is especially important as many PyTorch external users are interested in CUDA upgrades.

## 2. Modify scripts to install the new CUDA for our Linux containers.
There are three types of Docker containers we maintain in order to build Linux binaries: `conda`, `libtorch`, and `manywheel`. They all require installing CUDA and then updating code references in respective build scripts/Dockerfiles. (**Code reference**: [PR 719](https://github.com/pytorch/builder/pull/719), [PR 720](https://github.com/pytorch/builder/pull/720), and [PR 724](https://github.com/pytorch/builder/pull/724), [PR 888 done for 11.5](https://github.com/pytorch/builder/pull/888))
1. Modifying [`install_cuda.sh`](common/install_cuda.sh):
    1. Find the CUDA install link [here](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&=Debian&target_version=10&target_type=runfile_local)
    2. Get the cudnn link from NVIDIA on the PyTorch Slack
    3. Run the `install_113` chunk of code on your devbox to make sure it works.
    4. Check [this link](https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/) to see if you need to add/remove any architectures to the nvprune list.
    5. Go into your cuda-11.3 folder and make sure what you're pruning actually exists. Update versions as needed, especially the visual tools like `nsight-systems`.
2. Add setup for our Docker images in respective `libtorch`, `conda`, and `manywheel` scripts/Dockerfiles:
    1. For `conda` and `libtorch`, the code changes are usually copy-paste. For `manywheel`, you should manually verify the versions of the shared libraries with the CUDA you downloaded before.
    2. To test that your code works, from the root builder repo, run something similar to `export CUDA_VERSION=11.3 && ./conda/build_docker.sh` for the `conda` images. You can extend this to the other images.
    3. Create new repo to host manylinux-cuda images for example : https://hub.docker.com/r/pytorch/manylinux-cuda115 . And give bots write and read acceess to this repo. This step to be removed once following [issue](https://github.com/pytorch/builder/issues/901) is addressed
    4. Push the images to Docker Hub. This step should be automated with the help with GitHub Actions in the `pytorch/builder` repo. Make sure to update the `cuda_version` to the version you're adding in respective YAMLs, such as `.github/workflows/build-manywheel-images.yml`, `.github/workflows/build-conda-images.yml`, `.github/workflows/build-libtorch-images.yml`.
    5. Verify that each of the workflows that push the images succeed by selecting and verifying them in the [Actions page](https://github.com/pytorch/builder/actions/workflows/build-libtorch-images.yml) of pytorch/builder. Furthermore, check [https://hub.docker.com/r/pytorch/manylinux-builder/tags](https://hub.docker.com/r/pytorch/manylinux-builder/tags), [https://hub.docker.com/r/pytorch/libtorch-cxx11-builder/tags](https://hub.docker.com/r/pytorch/libtorch-cxx11-builder/tags), and [https://hub.docker.com/r/pytorch/conda-builder/tags](https://hub.docker.com/r/pytorch/conda-builder/tags) to verify that the right tags exist for all three types of images.

## 3. Modify code to install the new CUDA for Windows
**Code reference**: [PR 728](https://github.com/pytorch/builder/pull/728) and followup fixes in [PR 751](https://github.com/pytorch/builder/pull/751), [PR 755](https://github.com/pytorch/builder/pull/755), and [PR 806](https://github.com/pytorch/builder/pull/806)
1. To get the CUDA install link, just like with Linux, go [here](https://developer.nvidia.com/cuda-downloads?target_os=Windows&target_arch=x86_64&target_version=10&target_type=exe_local) and upload that `.exe` file to our S3 bucket [ossci-windows](https://s3.console.aws.amazon.com/s3/buckets/ossci-windows?region=us-east-1&tab=objects).
2. To get the cuDNN install link, you could ask NVIDIA, but you could also just sign up for an NVIDIA account and access the needed `.zip` file at this [link](https://developer.nvidia.com/rdp/cudnn-download). First click on `cuDNN Library for Windows (x86)` and then upload that zip file to our S3 bucket.
3. NOTE: When you upload files to S3, make sure to make these objects publicly readable so that our CI can access them!
4. Most times, you have to upgrade the driver install for newer versions, which would look like [updating the `windows/internal/driver_update.bat` file](https://github.com/pytorch/builder/commit/9b997037e16eb3bc635e28d101c3297d7e4ead29)
    1. Please check the CUDA Toolkit and Minimum Required Driver Version for CUDA minor version compatibility table  in [the release notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html) to see if a driver update is necessary.

## 4. Update MAGMA.
Compile MAGMA with the new CUDA version.
1. Our linux CUDA jobs use conda, so we need to build magma-cuda113 and push it to anaconda. (**Code reference**: [PR 721](https://github.com/pytorch/builder/pull/721)).
    1. Currently, this is mainly copy-paste in [`magma/Makefile`](magma/Makefile) if there are no major code API changes/deprecations to the CUDA version. Previously, we've needed to add patches to MAGMA, so this may be something to check with NVIDIA about.
    2. To push the package, please update build-magma-linux workflow [PR 897](https://github.com/pytorch/builder/pull/897).
    3. NOTE: This step relies on the conda-builder image (changes to `.github/workflows/build-conda-images.yml`), so make sure you have pushed the new conda-builder prior. Validate this step by logging into anaconda.org and seeing your package deployed for example [here](https://anaconda.org/pytorch/magma-cuda115)
2. Our windows jobs download MAGMA binaries from our S3 `ossci-windows` bucket, which means that those binaries need to exist.
    1. Lucky for you! There is a GitHub Actions workflow (as of [PR 762](https://github.com/pytorch/builder/pull/762)) that automates this upload when you update `windows/internal/build_magma.bat` to deal with your new CUDA version. Also remember to update the `cuda_version` in `.github/workflows/build-magma-windows.yml` to be the new version. (**Code reference**: [PR 751](https://github.com/pytorch/builder/pull/751))
    2. NOTE: this step should occur AFTER you update the Windows builder code so that the new version is installed correctly.

## 5. Add the new CUDA version to OSS CI.
Testing the new version in CI is crucial for finding regressions and should be done ASAP along with the next step (I am simply putting this one first as it is usually easier).
1. If the new CUDA version requires a new driver (see #1 sub-bullet), the CI and binaries would also need the new driver. Find the driver download [here](https://www.nvidia.com/en-us/drivers/unix/) and update the link like [so](https://github.com/pytorch/pytorch/commit/fcf8b712348f21634044a5d76a69a59727756357).
    1. Please check the Driver Version table in [the release notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html) to see if a driver update is necessary.
2. For Linux, we need to update code to use the magma we built! This can be done in the same PR when you actually add Linux CI, but here's an independent example for 11.2: [PR 50559](https://github.com/pytorch/pytorch/pull/50559)
3. The configuration files will be subject to change, but usually you just have to replace an older CUDA version with the new version you're adding. **Code reference for 11.2**: [PR 51888](https://github.com/pytorch/pytorch/pull/51888) for Linux and [PR 51598](https://github.com/pytorch/pytorch/pull/51598) for Windows, and **code reference for 11.3** where we just replaced verbatim yaml and updated magma for conda for Linux: [PR 57223 for Windows](https://github.com/pytorch/pytorch/pull/57223) and [PR 57222 for Linux](https://github.com/pytorch/pytorch/pull/57222)
4. For Windows you may need to rebuild the test AMI, please refer to this [PR](https://github.com/pytorch/test-infra/pull/154) . After this is done, run the release of Windows AMI using this [proecedure](https://github.com/pytorch/test-infra/tree/main/aws/ami/windows). As time of this writing this is manual steps performed on dev machine. Please note that packer, aws cli needs to be installed and configured!
5. After step 4 is complete and new Windows AMI have been deployed to AWS. We need to deploy the new AMI to our canary environment (https://github.com/pytorch/pytorch-canary) through https://github.com/fairinternal/pytorch-gha-infra . After this is completed Submit the code for windows workflows to https://github.com/pytorch/pytorch-canary and make sure all test are passing.
6. After that we can deploy the Windows AMI out to prod using the same pytorch-gha-infra repository.
7. It is likely that there will be tests that no longer pass with the new CUDA version or GPU driver. Disable them for the time being, notify people who can help, and make issues to track them (like [so](https://github.com/pytorch/pytorch/issues/57482)).

## 6. Add the new CUDA version to the nightly binaries matrix.
Adding the new version to nightlies allows PyTorch binaries compiled with the new CUDA version to be available to users through `conda` or `pip` or just raw `libtorch`.
1. The difficulty in this task is NOT changing the config--you only need to modify this [line](https://github.com/pytorch/pytorch/blob/master/.circleci/cimodel/data/dimensions.py#L6)--but the debugging process that ensues.
2. Since this change should not touch other build jobs and it is very likely you would be running these jobs on the CI frequently, I'd advise reducing the config to only the build jobs for the new CI version and to use your own fork of `pytorch/builder`. **Code reference**: [PR 57522](https://github.com/pytorch/pytorch/pull/57522).
3. Testing nightly builds is done as follows:
    - Make sure your commit to master passed all the test and there are no failures, otherwise the next step will not work
    - Make sure your changes are promoted to viable/strict branch: https://github.com/pytorch/pytorch/tree/viable/strict . Run viable/strict promotion job to promote from master to viable/strict 
    - After your changes are promoted to viable/strict. Run nighly build job.
    - Make sure your changes made to nightly branch https://github.com/pytorch/pytorch/tree/nightly
    - Make sure all nightly build succeeded before continuing to Step #6
4. Don't be afraid to ask questions when you're stuck on any bug!

## 7. Add the new version to torchvision and torchaudio CI.
Torchvision and torchaudio is usually a dependency for installing PyTorch for most of our users. This is why it is important to also
propagate the CI changes so that torchvision and torchaudio can be packaged for the new CUDA version as well.
1. A code sample for torchvision: [PR 4248](https://github.com/pytorch/vision/pull/4248) 
2. A code sample for torchaudio: [PR 2067](https://github.com/pytorch/audio/pull/2067) 
3. Almost every change in the above sample is copy-pasted from either itself or other existing parts of code in the
builder repo. The difficulty again is not changing the config but rather verifying and debugging any failing builds.

Congrats! PyTorch now has support for a new CUDA version and you made it happen!
