# s3_management

This directory houses scripts to maintain the s3 HTML indices for https://download.pytorch.org/whl

## Building the image

```
make build-image
```

## Pushing the image

```
make push-image
```

## Running the image

```
docker run --rm -it -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID pytorch/manage_s3_html all
```
