#!/usr/bin/env python

import argparse
import hashlib
import io
import tempfile

from os import path
from collections import defaultdict
from typing import List, Type, Dict, Set, TypeVar, Generator, Optional
from re import sub, match

import botocore
import botocore.exceptions
import boto3
import tqdm


S3 = boto3.resource('s3')
CLIENT = boto3.client('s3')
BUCKET = S3.Bucket('pytorch')
BASE_URL = "https://download.pytorch.org"

ACCEPTED_FILE_EXTENSIONS = ("whl", "zip")
ACCEPTED_SUBDIR_PATTERNS = [
    r"cu[0-9]+",           # for cuda
    r"rocm[0-9]+\.[0-9]+", # for rocm
    "cpu",
]
PREFIXES_WITH_HTML = {
    "whl": "torch_stable.html",
    "whl/test": "torch_test.html",
    "whl/nightly": "torch_nightly.html"
}

# How many packages should we keep of a specific package?
KEEP_THRESHOLD = 60

S3IndexType = TypeVar('S3IndexType', bound='S3Index')


class S3Index:
    def __init__(
            self: S3IndexType,
            objects: List[str],
            prefix: str
    ) -> None:
        self.objects = objects
        self.prefix = prefix.rstrip("/")
        # lazy load checksums since they could take a while to load
        self.checksums = dict()
        self.html_name = PREFIXES_WITH_HTML[self.prefix]
        # should dynamically grab subdirectories like whl/test/cu101
        # so we don't need to add them manually anymore
        self.subdirs = {
            path.dirname(obj) for obj in objects if path.dirname != prefix
        }

    def nightly_packages_to_show(self: S3IndexType) -> Set[str]:
        """Finding packages to show based on a threshold we specify

        Basically takes our S3 packages, normalizes the version for easier
        comparisons, then iterates over normalized versions untill we reach a
        threshold and then starts adding package to delete after that threshold
        has been reached

        After figuring out what versions we'd like to hide we iterate over
        our original object list again and pick out the full paths to the
        packages that are included in the list of versions to delete
        """
        # also includes versions without GPU specifier (i.e. cu102) for easier
        # sorting, sorts in reverse to put the most recent versions first
        all_sorted_packages = sorted(
            {self.normalize_package_version(obj) for obj in self.objects},
            reverse=True,
        )
        packages: Dict[str, int] = defaultdict(int)
        to_hide: Set[str] = set()
        for obj in all_sorted_packages:
            package_name = path.basename(obj).split('-')[0]
            if packages[package_name] >= KEEP_THRESHOLD:
                to_hide.add(obj)
            else:
                packages[package_name] += 1
        return set(self.objects).difference({
            obj for obj in self.objects
            if self.normalize_package_version(obj) in to_hide
        })

    def normalize_package_version(self: S3IndexType, obj: str) -> str:
        # removes the GPU specifier from the package name as well as
        # unnecessary things like the file extension, architecture name, etc.
        return sub(
            r"%2B.*",
            "",
            "-".join(path.basename(obj).split("-")[:2])
        )

    def pep503_normalize(self, obj: str) -> str:
        return sub(r"[-_.]+", "-", obj).lower()

    def get_sha256(self, obj: str) -> str:
        checksum_key = obj.replace(".whl", ".sha256")
        try:
            # if checksum exists, don't upload
            return BUCKET.objects.filter(Prefix=checksum_key).load()
        except botocore.exceptions.ClientError as exc:
            # If we don't get a 404 then something else went horribly wrong
            if int(exc.response['Error']['Code']) != 404:
                raise exc
            fileobj = io.BytesIO()
            BUCKET.download_fileobj(Key=obj, Fileobj=fileobj)
            checksum = hashlib.sha256(fileobj.getbuffer()).hexdigest()
            return checksum

    def get_checksums(
            self,
            objects: Optional[List[str]]=None
    ) -> Dict[str, str]:
        objects = objects or self.objects
        if not self.checksums:
            for obj in tqdm.tqdm(objects):
                checksum_key = obj.replace(".whl", ".sha256")
                self.checksums[checksum_key] = self.get_sha256(obj)
        return self.checksums

    def to_pep503_html(self) -> Dict[str, str]:
        objects = (
            self.nightly_packages_to_show() if self.prefix == 'whl/nightly'
            else self.objects
        )
        links: Dict[str, List[str]] = defaultdict(list)
        checksums = self.get_checksums(objects)
        for obj in tqdm.tqdm(objects):
            # escape '+'
            sanitized_obj = obj.replace("+", "%2B")
            sanitized_obj_base = path.basename(sanitized_obj)
            package_name = self.pep503_normalize(
                self.normalize_package_version(sanitized_obj).split("-")[0]
            )
            checksum = self.get_sha256(sanitized_obj)
            hyperlink = (
                f'{BASE_URL}/{sanitized_obj}#sha256={checksum}'
            )
            links[package_name].append(
                f'<a href="{hyperlink}">{sanitized_obj_base}</a><br/>'
            )
        out: Dict[str, str] = {
            f"{package_name}/index.html": "\n".join(contents)
            for package_name, contents in links.items()
        }
        out["index.html"] = "\n".join([
            f'<a href="{package_name}/">{package_name}</a><br/>'
            for package_name in links.keys()
        ])
        return out

    def upload_pep503_html(self) -> None:
        html = self.to_pep503_html()
        for index_name, content in tqdm.tqdm(html.items()):
            print(f"INFO Uploading {index_name}")
            BUCKET.Object(
                key=f"simple/{self.prefix}/{index_name}"
            ).put(
                ACL='public-read',
                CacheControl='no-cache,no-store,must-revalidate',
                ContentType='text/html',
                Body=content
            )

    def upload_checksums(self, force: bool = False) -> None:
        for checksum_key, checksum in tqdm.tqdm(self.checksums.items()):
            try:
                # if checksum exists, don't upload
                BUCKET.objects.filter(Prefix=checksum_key).load()
            except botocore.exceptions.ClientError as exc:
                # If we don't get a 404 then something else went horribly wrong
                if int(exc.response['Error']['Code']) != 404:
                    raise exc
                print(f"INFO Uploading {checksum_key}")
                BUCKET.Object(
                    key=f"{checksum_key}"
                ).put(
                    ACL='public-read',
                    CacheControl='must-revalidate',
                    ContentType='text/html',
                    Body=checksum
                )

    def to_legacy_html(self, subdir: Optional[str]=None) -> str:
        """Generates a string that can be used as the HTML index

        Takes our objects and transforms them into HTML that have historically
        been used by pip for installing pytorch.

        NOTE: These are not PEP 503 compliant but are here for legacy purposes
        """
        objects = (
            self.nightly_packages_to_show() if self.prefix == 'whl/nightly'
            else self.objects
        )
        out: List[str] = []
        if not subdir:
            subdir = self.prefix
        # make sure we strip any trailing slashes
        subdir = subdir.rstrip("/")
        is_root = subdir == self.prefix
        for obj in objects:
            obj_at_root = path.dirname(obj) == self.prefix
            if not obj_at_root and not obj.startswith(subdir):
                continue
            # escape '+'
            sanitized_obj = obj.replace("+", "%2B")
            # Strip our prefix
            sanitized_obj = obj.replace(subdir, "", 1)
            if sanitized_obj.startswith('/'):
                sanitized_obj = sanitized_obj.lstrip("/")
            # we include objects at our root prefix so that users can still
            # install packages like torchaudio / torchtext even if they want
            # to install a specific GPU arch of torch / torchvision
            if not is_root and obj_at_root:
                # strip root prefix
                sanitized_obj = obj.replace(self.prefix, "", 1).lstrip("/")
                sanitized_obj = f"../{sanitized_obj}"
            out.append(f'<a href="{sanitized_obj}"</a>{sanitized_obj}<br>')
        return "\n".join(sorted(out))

    def upload_legacy_html(self) -> None:
        for subdir in self.subdirs:
            print(f"INFO Uploading {subdir}/{self.html_name}")
            BUCKET.Object(
                key=f"{subdir}/{self.html_name}"
            ).put(
                ACL='public-read',
                CacheControl='no-cache,no-store,must-revalidate',
                ContentType='text/html',
                Body=self.to_legacy_html(subdir=subdir)
            )


    @classmethod
    def from_S3(cls: Type[S3IndexType], prefix: str) -> S3IndexType:
        objects = []
        checksums: Dict[str, str] = dict()
        prefix = prefix.rstrip("/")
        for obj in BUCKET.objects.filter(Prefix=prefix):
            is_acceptable = any([path.dirname(obj.key) == prefix] + [
                match(
                    f"{prefix}/{pattern}",
                    path.dirname(obj.key)
                )
                for pattern in ACCEPTED_SUBDIR_PATTERNS
            ]) and obj.key.endswith(ACCEPTED_FILE_EXTENSIONS)
            if is_acceptable:
                objects.append(obj.key)
        return cls(objects, prefix)

def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser("Manage S3 HTML indices for PyTorch")
    parser.add_argument(
        "prefix",
        type=str,
        choices=list(PREFIXES_WITH_HTML.keys()) + ["all"]
    )
    return parser

def main():
    parser = create_parser()
    args = parser.parse_args()
    if args.prefix == 'all':
        for prefix in PREFIXES_WITH_HTML.keys():
            print(f"INFO: Uploading indices for '{prefix}'")
            idx = S3Index.from_S3(prefix=prefix)
            idx.upload_legacy_html()
    else:
        print(f"INFO: Uploading indices for '{args.prefix}'")
        idx = S3Index.from_S3(prefix=args.prefix)
        idx.upload_legacy_html()

if __name__ == "__main__":
    main()
