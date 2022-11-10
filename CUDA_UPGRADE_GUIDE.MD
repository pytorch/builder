# CUDA Upgrade Guide/Runbook

So you wanna upgrade PyTorch to support a new CUDA? Follow these steps in order! They are adapted from previous CUDA upgrade processes.

## 0. Before starting upgrade process

### A. Currently Supported CUDA and CUDNN Libraries
Here is the supported matrix for CUDA and CUDNN

| CUDA | CUDNN | additional details |
| --- | --- | --- |
| 11.6 | 8.3.2.44 | Stable CUDA Release |
| 11.7 | 8.5.0.96 | Latest CUDA Release |


### B. Check the package availability

Package availability to validate before starting upgrade process :

1) CUDA and CUDNN is available for Linux and Windows:
https://developer.download.nvidia.com/compute/cuda/11.5.0/local_installers/cuda_11.5.0_495.29.05_linux.run
https://developer.download.nvidia.com/compute/redist/cudnn/v8.3.2/local_installers/11.5/

2) CUDA is available on conda via nvidia channel : https://anaconda.org/nvidia/cuda/files

3) CudaToolkit is available on conda via nvidia channel: https://anaconda.org/nvidia/cudatoolkit/files

4) CUDA is available on Docker hub images : https://hub.docker.com/r/nvidia/cuda
   Following example is for cuda 11.5: https://gitlab.com/nvidia/container-images/cuda/-/tree/master/dist/11.5.1/ubuntu2004/runtime
   (Make sure to use version without CUDNN, it should be installed separately by install script)

5) Validate new driver availability: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html. Check following table: Table 3. CUDA Toolkit and Corresponding Driver Versions


## 1. Maintain Progress and Updates
Make an issue to track the progress, for example [#56721: Support 11.3](https://github.com/pytorch/pytorch/issues/56721). This is especially important as many PyTorch external users are interested in CUDA upgrades.

## 2. Modify scripts to install the new CUDA for Conda Docker Linux containers.
There are three types of Docker containers we maintain in order to build Linux binaries: `conda`, `libtorch`, and `manywheel`. They all require installing CUDA and then updating code references in respective build scripts/Dockerfiles.  This step is about conda.

1. Follow this [PR 992](https://github.com/pytorch/builder/pull/992) for all steps in this section
2. Find the CUDA install link [here](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&=Debian&target_version=10&target_type=runfile_local)
3. Get the cudnn link from NVIDIA on the PyTorch Slack
4. Modify [`install_cuda.sh`](common/install_cuda.sh)
5. Run the `install_116` chunk of code on your devbox to make sure it works.
6. Check [this link](https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/) to see if you need to add/remove any architectures to the nvprune list.
7. Go into your cuda-11.6 folder and make sure what you're pruning actually exists. Update versions as needed, especially the visual tools like `nsight-systems`.
8. Add setup for our Docker `conda` scripts/Dockerfiles
9. To test that your code works, from the root builder repo, run something similar to `export CUDA_VERSION=11.3 && ./conda/build_docker.sh` for the `conda` images.
10. Validate conda-builder docker hub [cuda11.6](https://hub.docker.com/r/pytorch/conda-builder/tags?page=1&name=cuda11.6) to see that images have been built and correctly tagged. These images are used in the next step to build Magma for linux.

## 3. Update Magma for Linux
Build Magma for Linux. Our Linux CUDA jobs use conda, so we need to build magma-cuda116 and push it to anaconda:
1. Follow this [PR 997](https://github.com/pytorch/builder/pull/997) for all steps in this section
2. Currently, this is mainly copy-paste in [`magma/Makefile`](magma/Makefile) if there are no major code API changes/deprecations to the CUDA version. Previously, we've needed to add patches to MAGMA, so this may be something to check with NVIDIA about.
3. To push the package, please update build-magma-linux workflow [PR 897](https://github.com/pytorch/builder/pull/897).
4. NOTE: This step relies on the conda-builder image (changes to `.github/workflows/build-conda-images.yml`), so make sure you have pushed the new conda-builder prior. Validate this step by logging into anaconda.org and seeing your package deployed for example [here](https://anaconda.org/pytorch/magma-cuda115)

## 4. Modify scripts to install the new CUDA for Libtorch and Manywheel Docker Linux containers. Modify builder supporting scripts
There are three types of Docker containers we maintain in order to build Linux binaries: `conda`, `libtorch`, and `manywheel`. They all require installing CUDA and then updating code references in respective build scripts/Dockerfiles.  This step is about libtorch and manywheel containers.

Add setup for our Docker `libtorch` and `manywheel`:
1. Follow this PR [PR 1003](https://github.com/pytorch/builder/pull/1003) for all steps in this section
2. For `libtorch`, the code changes are usually copy-paste. For `manywheel`, you should manually verify the versions of the shared libraries with the CUDA you downloaded before.
3. This is Manual Step: Create a ticket for PyTorch Dev Infra team to Create a new repo to host manylinux-cuda images in docker hub, for example, https://hub.docker.com/r/pytorch/manylinux-cuda115. This repo should have public visibility and read & write access for bots. This step can be removed once the following [issue](https://github.com/pytorch/builder/issues/901) is addressed.
4. Push the images to Docker Hub. This step should be automated with the help with GitHub Actions in the `pytorch/builder` repo. Make sure to update the `cuda_version` to the version you're adding in respective YAMLs, such as `.github/workflows/build-manywheel-images.yml`, `.github/workflows/build-conda-images.yml`, `.github/workflows/build-libtorch-images.yml`.
5. Verify that each of the workflows that push the images succeed by selecting and verifying them in the [Actions page](https://github.com/pytorch/builder/actions/workflows/build-libtorch-images.yml) of pytorch/builder. Furthermore, check [https://hub.docker.com/r/pytorch/manylinux-builder/tags](https://hub.docker.com/r/pytorch/manylinux-builder/tags), [https://hub.docker.com/r/pytorch/libtorch-cxx11-builder/tags](https://hub.docker.com/r/pytorch/libtorch-cxx11-builder/tags) to verify that the right tags exist for manylinux and libtorch types of images.
6. Finally before enabling nightly binaries and CI builds we should make sure we post following PRs in [PR 1015](https://github.com/pytorch/builder/pull/1015) [PR 1017](https://github.com/pytorch/builder/pull/1017) and [this commit](https://github.com/pytorch/builder/commit/7d5e98f1336c7cb84c772604c5e0d1acb59f2d72) to enable the new CUDA build in wheels and conda.

## 5. Modify code to install the new CUDA for Windows and update MAGMA for Windows

1. Follow this [PR 999](https://github.com/pytorch/builder/pull/999) for all steps in this section
2. To get the CUDA install link, just like with Linux, go [here](https://developer.nvidia.com/cuda-downloads?target_os=Windows&target_arch=x86_64&target_version=10&target_type=exe_local) and upload that `.exe` file to our S3 bucket [ossci-windows](https://s3.console.aws.amazon.com/s3/buckets/ossci-windows?region=us-east-1&tab=objects).
3. To get the cuDNN install link, you could ask NVIDIA, but you could also just sign up for an NVIDIA account and access the needed `.zip` file at this [link](https://developer.nvidia.com/rdp/cudnn-download). First click on `cuDNN Library for Windows (x86)` and then upload that zip file to our S3 bucket.
4. NOTE: When you upload files to S3, make sure to make these objects publicly readable so that our CI can access them!
5. Most times, you have to upgrade the driver install for newer versions, which would look like [updating the `windows/internal/driver_update.bat` file](https://github.com/pytorch/builder/commit/9b997037e16eb3bc635e28d101c3297d7e4ead29)
    1. Please check the CUDA Toolkit and Minimum Required Driver Version for CUDA minor version compatibility table  in [the release notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html) to see if a driver update is necessary.
6. Compile MAGMA with the new CUDA version. Update `.github/workflows/build-magma-windows.yml` to include new version.
7. Validate Magma builds by going to S3 [ossci-windows](https://s3.console.aws.amazon.com/s3/buckets/ossci-windows?region=us-east-1&tab=objects). And querying for ```magma_```

## 6. Generate new Windows AMI, test and deploy to canary and prod.

Please note, since this step currently requires access to corporate AWS, this step should be performed by Meta employee. To be removed, once automated.
1. For Windows you will need to rebuild the test AMI, please refer to this [PR](https://github.com/pytorch/test-infra/pull/452). After this is done, run the release of Windows AMI using this [proecedure](https://github.com/pytorch/test-infra/tree/main/aws/ami/windows). As time of this writing this is manual steps performed on dev machine. Please note that packer, aws cli needs to be installed and configured!
2. After step 1 is complete and new Windows AMI have been deployed to AWS. We need to deploy the new AMI to our canary environment (https://github.com/pytorch/pytorch-canary) through https://github.com/fairinternal/pytorch-gha-infra example : [PR](https://github.com/fairinternal/pytorch-gha-infra/pull/31) . After this is completed Submit the code for all windows workflows to https://github.com/pytorch/pytorch-canary and make sure all test are passing for all CUDA versions. 
3. After that we can deploy the Windows AMI out to prod using the same pytorch-gha-infra repository.

## 7. Add the new CUDA version to the nightly binaries matrix.
Adding the new version to nightlies allows PyTorch binaries compiled with the new CUDA version to be available to users through `conda` or `pip` or just raw `libtorch`.
1. If the new CUDA version requires a new driver (see #1 sub-bullet), the CI and binaries would also need the new driver. Find the driver download [here](https://www.nvidia.com/en-us/drivers/unix/) and update the link like [so](https://github.com/pytorch/pytorch/commit/fcf8b712348f21634044a5d76a69a59727756357).
    1. Please check the Driver Version table in [the release notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html) to see if a driver update is necessary.
2. Follow this [PR 81095](https://github.com/pytorch/pytorch/pull/81095) for steps 2-4 in this section.
3. Once [PR 81095](https://github.com/pytorch/pytorch/pull/81095) is created make sure to attach ciflow/binaries, ciflow/binaries_conda, ciflow/binaries_wheel, ciflow/nightly labels to this PR. And make sure all the new workflow with new CUDA version terminate successfully.
4. Testing nightly builds is done as follows:
    - Make sure your commit to master passed all the test and there are no failures, otherwise the next step will not work
    - Make sure your changes are promoted to viable/strict branch: https://github.com/pytorch/pytorch/tree/viable/strict . Run viable/strict promotion job to promote from master to viable/strict
    - After your changes are promoted to viable/strict. Run nighly build job.
    - Make sure your changes made to nightly branch https://github.com/pytorch/pytorch/tree/nightly
    - Make sure all nightly build succeeded before continuing to Step #6

## 8. Add the new CUDA version to OSS CI.
Testing the new version in CI is crucial for finding regressions and should be done ASAP along with the next step (I am simply putting this one first as it is usually easier).
1. The configuration files will be subject to change, but usually you just have to replace an older CUDA version with the new version you're adding. **Code reference for 11.5**: [PR 68745](https://github.com/pytorch/pytorch/pull/68745) for Linux and [PR 69377](https://github.com/pytorch/pytorch/pull/69377) for Windows, and **code reference for 11.3** where we just replaced verbatim yaml and updated magma for conda for Linux: [PR 57223 for Windows](https://github.com/pytorch/pytorch/pull/57223) and [PR 57222 for Linux](https://github.com/pytorch/pytorch/pull/57222)
2. IMPORTANT NOTE: the CI is not always automatically triggered when you edit the workflow files! Ensure that the new CI job for the new CUDA version is showing up in the PR signal box.
If it is not there, make sure you add the correct ciflow label (ciflow/periodic, for example) to trigger the test. Just because the CI is green on your pull request does NOT mean
the test has been run and is green.
3. It is likely that there will be tests that no longer pass with the new CUDA version or GPU driver. Disable them for the time being, notify people who can help, and make issues to track them (like [so](https://github.com/pytorch/pytorch/issues/57482)).

## 9. Add the new version to torchvision and torchaudio CI.
Torchvision and torchaudio is usually a dependency for installing PyTorch for most of our users. This is why it is important to also
propagate the CI changes so that torchvision and torchaudio can be packaged for the new CUDA version as well.
1. A code sample for torchvision: [PR 4248](https://github.com/pytorch/vision/pull/4248)
2. A code sample for torchaudio: [PR 2067](https://github.com/pytorch/audio/pull/2067)
3. Almost every change in the above sample is copy-pasted from either itself or other existing parts of code in the
builder repo. The difficulty again is not changing the config but rather verifying and debugging any failing builds.

Congrats! PyTorch now has support for a new CUDA version and you made it happen!
