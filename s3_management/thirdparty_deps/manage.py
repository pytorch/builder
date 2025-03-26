#!/usr/bin/env python

from botocore.config import Config
from botocore.exceptions import ClientError
from re import search, match
from typing import List, Dict
import argparse
import boto3
import requests
import validators
import yaml

boto_config = Config(
  retries={
    'max_attempts': 3,
    'mode': 'standard'
  }
)

CLIENT = boto3.client('s3', config=boto_config)


def stream_file_s3(url: str, bucket: str, key: str):
    """
    Stream file to S3.
    """
    print(f'Downloading file: {url}')
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        print(f'Uploading file: {url} to {key}')
        CLIENT.upload_fileobj(r.raw, bucket, key, ExtraArgs={'ACL': 'public-read'})
        print(f'Uploaded file: {key}')


def exists_on_s3(bucket: str, key: str) -> bool:
    """
    Checks if the file already exists on S3.
    :param bucket: s3 bucket name
    :param key: the key of the file on S3
    :return: True if the file already exists on S3, False otherwise
    """
    try:
        CLIENT.head_object(Bucket=bucket, Key=key)
        return True
    except ClientError as e:
        if e.response['ResponseMetadata']['HTTPStatusCode'] == 404:
            return False
        # rethrow with original error
        raise Exception(f'Error checking if key {key} exists on S3: {e}')


def validate_key_s3(key: str) -> bool:
    """
    Validates the key of the file on S3.
    :param key: s3 key
    :return:
    """
    return match(r'^[a-zA-Z\d!*\'"()_./-]+$', key) and \
        not search(r'//|^/|/$|/\.\./|\\', key)


def main():
    parser = argparse.ArgumentParser("Sync urls to Pytorch S3")
    parser.add_argument('file', help='the yaml file containing the list of urls to cache on S3')
    args = parser.parse_args()

    with open(args.file, 'r') as f:
        config: Dict[str, any] = yaml.load(f, Loader=yaml.SafeLoader)

        # a dict of allowed bucket names to the list of allowed s3 key prefixes per each bucket
        allowed_buckets_with_key_prefixes: Dict[str, List[str]] = config.get('validation', dict())
        urls: List[Dict[str, str]] = config.get('urls', [])

    if len(allowed_buckets_with_key_prefixes) == 0:
        print(f'`validation` section is required in the config file {args.file}')
        exit(1)

    for url in urls:
        bucket = url['bucket']
        key = url['key']
        url = url['url']

        if not validators.url(url):
            print(f'Invalid URL: {url}')
            exit(1)

        if not validate_key_s3(key):
            print(f'Invalid key format: {key}')
            exit(1)

        allowed_prefixes = allowed_buckets_with_key_prefixes.get(bucket)
        if allowed_prefixes is None:
            print(f'Bucket {bucket} is not allowed. Here is the list of allowed buckets: '
                  f'{list(allowed_buckets_with_key_prefixes.keys())}')
            exit(1)

        if not any(key.startswith(prefix) for prefix in allowed_prefixes):
            print(f'Invalid key: {key}, allowed key prefixes for bucket {bucket}: {allowed_prefixes}')
            exit(1)

        if exists_on_s3(bucket, key):
            print(f'File already exists on S3: {key}, skipping {url}')
            continue

        stream_file_s3(url, bucket, key)


if __name__ == "__main__":
    main()
