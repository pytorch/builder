# S3 Public Bucket Management GH Action

This directory houses docker image (github action) that allows uploading files to the public OSSCI S3 buckets
based on the given config. 

## Intended usage

* Create a `yml` config file in any of the pytorch org repos with relevant mappings of the public urls to their
    corresponding keys on OSSCI S3. See below for the config format.
* Create a workflow that invokes this action with the config and performs the sync.
    See below for an example. Workflow could be invoked either periodically, on push to `main` or manually.

## General info

Docker image name: `pytorch/sync_s3_thirdparty_deps`

## Building the image

```
make build-image
```

## Pushing the image

```
make push-image
```

## Running the image locally

Note: mounting a volume to access the config file.

```sh
docker run --rm -it -v "$(pwd):/mnt/conf" -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID \
    pytorch/sync_s3_thirdparty_deps /mnt/conf/urls-list.yml
```

## Github workflow example

```yaml
name: Update S3 HTML indices for download.pytorch.org
on:
  workflow_dispatch:

jobs:
  sync-s3-cache:
    runs-on: ubuntu-18.04
    steps:
      - name: checkout
        uses: actions/checkout@v3
      - name: Sync S3 file cache
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_S3_UPDATE_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_S3_UPDATE_SECRET_ACCESS_KEY }}
        uses: docker://pytorch/sync_s3_thirdparty_deps
        with:
          args: "path-to-config-in-checked-out-repo.yml"
```

## Config file example

```yaml
validation:       # "validation" section is mandatory
  ossci-linux:    # allowed S3 bucket name
    - "test/"     # list of allowed S3 key prefixes for the bucket
    - "cuda/",    #   a simple prefix substring validation is used
    - "cudnn/"
  ossci-macos:
    - "test/"
  ossci-windows:  
    - ""          # an example of the unrestricted access to the whole bucket

urls:
  - bucket: ossci-linux
    url: https://developer.download.nvidia.com/compute/redist/cudnn/v8.3.2/local_installers/11.5/cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz
    key: cudnn/cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz
  - bucket: ossci-windows
    url: https://developer.download.nvidia.com/compute/redist/cudnn/v8.3.2/local_installers/11.5/cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz
    key: cudnn/cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz
```