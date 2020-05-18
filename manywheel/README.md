- bump version in setup.py
- cut branch
- upload generated docs and add to version selector


## Building new wheels

Run this command:

```
nvidia-docker run -it --ipc=host --rm -v $(pwd):/remote soumith/manylinux-cuda92:latest bash
OR
nvidia-docker run -it --ipc=host --rm -v $(pwd):/remote soumith/manylinux-cuda100:latest bash
```

Exit the container, then back in the host, run:

```
# versioned, build all
export PYTORCH_REPO=pytorch
export PYTORCH_BRANCH=v1.1.0
export PYTORCH_BUILD_VERSION=1.1.0
export PYTORCH_BUILD_NUMBER=1
export TORCH_CONDA_BUILD_FOLDER=pytorch-1.1.0
export TORCH_PACKAGE_NAME=torch
export PIP_UPLOAD_FOLDER=""
export NIGHTLIES_ROOT_FOLDER="/private/home/soumith/local/builder/binaries_v1.1.0"
cd ../cron
./build_multiple.sh manywheel all all
./remote/build.sh

# single nightly build
export PYTORCH_REPO=pytorch
export PYTORCH_BRANCH=master
export PYTORCH_BUILD_VERSION=1.2.5
export PYTORCH_BUILD_NUMBER=1
export TORCH_CONDA_BUILD_FOLDER=pytorch-nightly
export TORCH_PACKAGE_NAME=torch
export PIP_UPLOAD_FOLDER=""
export NIGHTLIES_ROOT_FOLDER="/private/home/soumith/local/builder/binaries_nightly"
cd ../cron
./build_multiple.sh manywheel 3.6m cu100
./remote/build.sh

```

Once done, upload wheels via:

```
./upload.sh
```

Upload the default cuda wheels to PyPI:

```
mkdir wheelhouse_manylinux
cp wheelhouse92/*.whl wheelhouse_manylinux/
ls -1 wheelhouse_manylinux/*.whl | awk '{print("mv "$1 " " $1)}' | sed 's/-linux_/-manylinux1_/2' | bash
twine upload wheelhouse_manylinux/*.whl
```

Generate stable.html with URLs:

```
HTML_NAME=torch_stable.html cron/update_s3_htmls.sh
```

## Building Docker image

To build (Run from the root):

```
manywheel/deploy.sh
```
