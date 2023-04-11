#!/usr/bin/env python3
# Downloads domain pytorch and library packages from channel
# And backs them up to S3
# Do not use unless you know what you are doing
# Usage:  python backup_conda.py --version 1.6.0

import conda.api
import boto3
from typing import List, Optional
import urllib
import os
import hashlib
import argparse

S3 = boto3.resource('s3')
BUCKET = S3.Bucket('pytorch-backup')
_known_subdirs = ["linux-64", "osx-64", "osx-arm64", "win-64"]


def compute_md5(path:str) -> str:
    with open(path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def download_conda_package(package:str, version:Optional[str] = None, depends:Optional[str] = None, channel:Optional[str] = None) -> List[str]:
    packages = conda.api.SubdirData.query_all(package, channels = [channel] if channel is not None else None, subdirs = _known_subdirs)
    rc = []

    for pkg in packages:
        if version is not None and pkg.version != version:
            continue
        if depends is not None and depends not in pkg.depends:
            continue

        print(f"Downloading {pkg.url}...")
        os.makedirs(pkg.subdir, exist_ok = True)
        fname = f"{pkg.subdir}/{pkg.fn}"
        if not os.path.exists(fname):
            with open(fname, "wb") as f:
                with urllib.request.urlopen(pkg.url) as url:
                    f.write(url.read())
        if compute_md5(fname) != pkg.md5:
            print(f"md5 of {fname} is {compute_md5(fname)} does not match {pkg.md5}")
            continue
        rc.append(fname)

    return rc

def upload_to_s3(prefix: str, fnames: List[str]) -> None:
    for fname in fnames:
        BUCKET.upload_file(fname, f"{prefix}/{fname}")
        print(fname)



if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--version",
        help="PyTorch Version to backup",
        type=str,
        required = True
    )
    options = parser.parse_args()
    rc = download_conda_package("pytorch", channel = "pytorch", version = options.version)
    upload_to_s3(f"v{options.version}/conda", rc)

    for libname in ["torchvision", "torchaudio", "torchtext"]:
        print(f"processing {libname}")
        rc = download_conda_package(libname, channel = "pytorch", depends = f"pytorch {options.version}")
        upload_to_s3(f"v{options.version}/conda", rc)
