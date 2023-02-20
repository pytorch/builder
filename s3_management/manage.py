#!/usr/bin/env python

import argparse
import time

from os import path, makedirs
from datetime import datetime
from collections import defaultdict
from typing import Iterator, List, Type, Dict, Set, TypeVar, Optional
from re import sub, match, search
from packaging.version import parse

import boto3


S3 = boto3.resource('s3')
CLIENT = boto3.client('s3')
BUCKET = S3.Bucket('pytorch')

ACCEPTED_FILE_EXTENSIONS = ("whl", "zip", "tar.gz")
ACCEPTED_SUBDIR_PATTERNS = [
    r"cu[0-9]+",           # for cuda
    r"rocm[0-9]+\.[0-9]+", # for rocm
    "cpu",
]
PREFIXES_WITH_HTML = {
    "whl": "torch_stable.html",
    "whl/lts/1.8": "torch_lts.html",
    "whl/nightly": "torch_nightly.html",
    "whl/test": "torch_test.html",
}

# NOTE: This refers to the name on the wheels themselves and not the name of
# package as specified by setuptools, for packages with "-" (hyphens) in their
# names you need to convert them to "_" (underscores) in order for them to be
# allowed here since the name of the wheels is compared here
PACKAGE_ALLOW_LIST = {
    "Pillow",
    "certifi",
    "charset_normalizer",
    "cmake",
    "filelock",
    "idna",
    "lit",
    "mpmath",
    "nestedtensor",
    "networkx",
    "numpy",
    "packaging",
    "pytorch_triton",
    "requests",
    "sympy",
    "torch",
    "torcharrow",
    "torchaudio",
    "torchcsprng",
    "torchdata",
    "torchdistx",
    "torchrec",
    "torchtext",
    "torchvision",
    "typing_extensions",
    "urllib3",
}

# Should match torch-2.0.0.dev20221221+cu118-cp310-cp310-linux_x86_64.whl as:
# Group 1: torch-2.0.0.dev
# Group 2: 20221221
PACKAGE_DATE_REGEX = r"([a-zA-z]*-[0-9.]*.dev)([0-9]*)"

# How many packages should we keep of a specific package?
KEEP_THRESHOLD = 60

S3IndexType = TypeVar('S3IndexType', bound='S3Index')

def extract_package_build_time(full_package_name: str) -> datetime:
    result = search(PACKAGE_DATE_REGEX, full_package_name)
    if result is not None:
        try:
            return datetime.strptime(result.group(2), "%Y%m%d")
        except ValueError:
            # Ignore any value errors since they probably shouldn't be hidden anyways
            pass
    return datetime.now()

def between_bad_dates(package_build_time: datetime):
    start_bad = datetime(year=2022, month=8, day=17)
    end_bad = datetime(year=2022, month=12, day=30)
    return start_bad <= package_build_time <= end_bad


class S3Index:
    def __init__(self: S3IndexType, objects: List[str], prefix: str) -> None:
        self.objects = objects
        self.prefix = prefix.rstrip("/")
        self.html_name = PREFIXES_WITH_HTML[self.prefix]
        # should dynamically grab subdirectories like whl/test/cu101
        # so we don't need to add them manually anymore
        self.subdirs = {
            path.dirname(obj) for obj in objects if path.dirname != prefix
        }

    def nightly_packages_to_show(self: S3IndexType) -> Set[str]:
        """Finding packages to show based on a threshold we specify

        Basically takes our S3 packages, normalizes the version for easier
        comparisons, then iterates over normalized versions until we reach a
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
            key=lambda name_ver: parse(name_ver.split('-', 1)[-1]),
            reverse=True,
        )
        packages: Dict[str, int] = defaultdict(int)
        to_hide: Set[str] = set()
        for obj in all_sorted_packages:
            full_package_name = path.basename(obj)
            package_name = full_package_name.split('-')[0]
            package_build_time = extract_package_build_time(full_package_name)
            # Hard pass on packages that are included in our allow list
            if package_name not in PACKAGE_ALLOW_LIST:
                to_hide.add(obj)
                continue
            if packages[package_name] >= KEEP_THRESHOLD:
                to_hide.add(obj)
            elif between_bad_dates(package_build_time):
                to_hide.add(obj)
            else:
                packages[package_name] += 1
        return set(self.objects).difference({
            obj for obj in self.objects
            if self.normalize_package_version(obj) in to_hide
        })

    def is_obj_at_root(self, obj:str) -> bool:
        return path.dirname(obj) == self.prefix

    def _resolve_subdir(self, subdir: Optional[str] = None) -> str:
        if not subdir:
            subdir = self.prefix
        # make sure we strip any trailing slashes
        return subdir.rstrip("/")

    def gen_file_list(
        self,
        subdir: Optional[str]=None,
        package_name: Optional[str] = None
    ) -> Iterator[str]:
        objects = (
            self.nightly_packages_to_show() if self.prefix == 'whl/nightly'
            else self.objects
        )
        subdir = self._resolve_subdir(subdir) + '/'
        for obj in objects:
            if package_name is not None:
                if self.obj_to_package_name(obj) != package_name:
                    continue
            if self.is_obj_at_root(obj) or obj.startswith(subdir):
                yield obj

    def get_package_names(self, subdir: Optional[str] = None) -> List[str]:
        return sorted(set(self.obj_to_package_name(obj) for obj in self.gen_file_list(subdir)))

    def normalize_package_version(self: S3IndexType, obj: str) -> str:
        # removes the GPU specifier from the package name as well as
        # unnecessary things like the file extension, architecture name, etc.
        return sub(
            r"%2B.*",
            "",
            "-".join(path.basename(obj).split("-")[:2])
        )

    def obj_to_package_name(self, obj: str) -> str:
        return path.basename(obj).split('-', 1)[0]

    def to_legacy_html(
        self,
        subdir: Optional[str]=None
    ) -> str:
        """Generates a string that can be used as the HTML index

        Takes our objects and transforms them into HTML that have historically
        been used by pip for installing pytorch.

        NOTE: These are not PEP 503 compliant but are here for legacy purposes
        """
        out: List[str] = []
        subdir = self._resolve_subdir(subdir)
        is_root = subdir == self.prefix
        for obj in self.gen_file_list(subdir):
            # Strip our prefix
            sanitized_obj = obj.replace(subdir, "", 1)
            if sanitized_obj.startswith('/'):
                sanitized_obj = sanitized_obj.lstrip("/")
            # we include objects at our root prefix so that users can still
            # install packages like torchaudio / torchtext even if they want
            # to install a specific GPU arch of torch / torchvision
            if not is_root and self.is_obj_at_root(obj):
                # strip root prefix
                sanitized_obj = obj.replace(self.prefix, "", 1).lstrip("/")
                sanitized_obj = f"../{sanitized_obj}"
            out.append(f'<a href="{sanitized_obj}">{sanitized_obj}</a><br/>')
        return "\n".join(sorted(out))

    def to_simple_package_html(
        self,
        subdir: Optional[str],
        package_name: str
    ) -> str:
        """Generates a string that can be used as the package simple HTML index
        """
        out: List[str] = []
        # Adding html header
        out.append('<!DOCTYPE html>')
        out.append('<html>')
        out.append('  <body>')
        out.append('    <h1>Links for {}</h1>'.format(package_name.lower().replace("_","-")))
        for obj in sorted(self.gen_file_list(subdir, package_name)):
            out.append(f'    <a href="/{obj}">{path.basename(obj).replace("%2B","+")}</a><br/>')
        # Adding html footer
        out.append('  </body>')
        out.append('</html>')
        out.append('<!--TIMESTAMP {}-->'.format(int(time.time())))
        return '\n'.join(out)

    def to_simple_packages_html(
        self,
        subdir: Optional[str],
    ) -> str:
        """Generates a string that can be used as the simple HTML index
        """
        out: List[str] = []
        # Adding html header
        out.append('<!DOCTYPE html>')
        out.append('<html>')
        out.append('  <body>')
        for pkg_name in sorted(self.get_package_names(subdir)):
            out.append(f'    <a href="{pkg_name.replace("_","-")}/">{pkg_name.replace("_","-")}</a><br/>')
        # Adding html footer
        out.append('  </body>')
        out.append('</html>')
        out.append('<!--TIMESTAMP {}-->'.format(int(time.time())))
        return '\n'.join(out)

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

    def upload_pep503_htmls(self) -> None:
        for subdir in self.subdirs:
            print(f"INFO Uploading {subdir}/index.html")
            BUCKET.Object(
                key=f"{subdir}/index.html"
            ).put(
                ACL='public-read',
                CacheControl='no-cache,no-store,must-revalidate',
                ContentType='text/html',
                Body=self.to_simple_packages_html(subdir=subdir)
            )
            for pkg_name in self.get_package_names(subdir=subdir):
                compat_pkg_name = pkg_name.lower().replace("_", "-")
                print(f"INFO Uploading {subdir}/{compat_pkg_name}/index.html")
                BUCKET.Object(
                    key=f"{subdir}/{compat_pkg_name}/index.html"
                ).put(
                    ACL='public-read',
                    CacheControl='no-cache,no-store,must-revalidate',
                    ContentType='text/html',
                    Body=self.to_simple_package_html(subdir=subdir, package_name=pkg_name)
                )


    def save_legacy_html(self) -> None:
        for subdir in self.subdirs:
            print(f"INFO Saving {subdir}/{self.html_name}")
            makedirs(subdir, exist_ok=True)
            with open(path.join(subdir, self.html_name), mode="w", encoding="utf-8") as f:
                f.write(self.to_legacy_html(subdir=subdir))

    def save_pep503_htmls(self) -> None:
        for subdir in self.subdirs:
            print(f"INFO Saving {subdir}/index.html")
            makedirs(subdir, exist_ok=True)
            with open(path.join(subdir, "index.html"), mode="w", encoding="utf-8") as f:
                f.write(self.to_simple_packages_html(subdir=subdir))
            for pkg_name in self.get_package_names(subdir=subdir):
                makedirs(path.join(subdir, pkg_name), exist_ok=True)
                with open(path.join(subdir, pkg_name, "index.html"), mode="w", encoding="utf-8") as f:
                    f.write(self.to_simple_package_html(subdir=subdir, package_name=pkg_name))

    @classmethod
    def from_S3(cls: Type[S3IndexType], prefix: str) -> S3IndexType:
        objects = []
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
                sanitized_key = obj.key.replace("+", "%2B")
                objects.append(sanitized_key)
        return cls(objects, prefix)

def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser("Manage S3 HTML indices for PyTorch")
    parser.add_argument(
        "prefix",
        type=str,
        choices=list(PREFIXES_WITH_HTML.keys()) + ["all"]
    )
    parser.add_argument("--do-not-upload", action="store_true")
    parser.add_argument("--generate-pep503", action="store_true")
    return parser

def main():
    parser = create_parser()
    args = parser.parse_args()
    action = "Saving" if args.do_not_upload else "Uploading"
    if args.prefix == 'all':
        for prefix in PREFIXES_WITH_HTML.keys():
            print(f"INFO: {action} indices for '{prefix}'")
            idx = S3Index.from_S3(prefix=prefix)
            if args.do_not_upload:
                idx.save_legacy_html()
            else:
                idx.upload_legacy_html()
    else:
        print(f"INFO: {action} indices for '{args.prefix}'")
        idx = S3Index.from_S3(prefix=args.prefix)
        if args.do_not_upload:
            idx.save_legacy_html()
            if args.generate_pep503:
                idx.save_pep503_htmls()
        else:
            idx.upload_legacy_html()
            if args.generate_pep503:
                idx.upload_pep503_htmls()

if __name__ == "__main__":
    main()
