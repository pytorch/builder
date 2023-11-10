#!/usr/bin/env python

import argparse
import base64
import concurrent.futures
import dataclasses
import functools
import time

from os import path, makedirs
from datetime import datetime
from collections import defaultdict
from typing import Iterable, List, Type, Dict, Set, TypeVar, Optional
from re import sub, match, search
from packaging.version import parse as _parse_version, Version, InvalidVersion

import boto3


S3 = boto3.resource('s3')
CLIENT = boto3.client('s3')
BUCKET = S3.Bucket('pytorch')

ACCEPTED_FILE_EXTENSIONS = ("whl", "zip", "tar.gz")
ACCEPTED_SUBDIR_PATTERNS = [
    r"cu[0-9]+",            # for cuda
    r"rocm[0-9]+\.[0-9]+",  # for rocm
    "cpu",
]
PREFIXES_WITH_HTML = {
    "whl": "torch_stable.html",
    "whl/lts/1.8": "torch_lts.html",
    "whl/nightly": "torch_nightly.html",
    "whl/test": "torch_test.html",
    "libtorch": "index.html",
    "libtorch/nightly": "index.html",
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
    "colorama",
    "fbgemm_gpu",
    "filelock",
    "fsspec",
    "idna",
    "Jinja2",
    "lit",
    "MarkupSafe",
    "mpmath",
    "nestedtensor",
    "networkx",
    "numpy",
    "nvidia_cublas_cu11",
    "nvidia_cuda_cupti_cu11",
    "nvidia_cuda_nvrtc_cu11",
    "nvidia_cuda_runtime_cu11",
    "nvidia_cudnn_cu11",
    "nvidia_cufft_cu11",
    "nvidia_curand_cu11",
    "nvidia_cusolver_cu11",
    "nvidia_cusparse_cu11",
    "nvidia_nccl_cu11",
    "nvidia_nvtx_cu11",
    "nvidia_cublas_cu12",
    "nvidia_cuda_cupti_cu12",
    "nvidia_cuda_nvrtc_cu12",
    "nvidia_cuda_runtime_cu12",
    "nvidia_cudnn_cu12",
    "nvidia_cufft_cu12",
    "nvidia_curand_cu12",
    "nvidia_cusolver_cu12",
    "nvidia_cusparse_cu12",
    "nvidia_nccl_cu12",
    "nvidia_nvtx_cu12",
    "nvidia_nvjitlink_cu12",
    "packaging",
    "portalocker",
    "pytorch_triton",
    "pytorch_triton_rocm",
    "requests",
    "sympy",
    "torch",
    "torch_tensorrt",
    "torcharrow",
    "torchaudio",
    "torchcsprng",
    "torchdata",
    "torchdistx",
    "torchmetrics",
    "torchrec",
    "torchtext",
    "torchvision",
    "triton",
    "tqdm",
    "typing_extensions",
    "urllib3",
    "xformers",
}

# Should match torch-2.0.0.dev20221221+cu118-cp310-cp310-linux_x86_64.whl as:
# Group 1: torch-2.0.0.dev
# Group 2: 20221221
PACKAGE_DATE_REGEX = r"([a-zA-z]*-[0-9.]*.dev)([0-9]*)"

# How many packages should we keep of a specific package?
KEEP_THRESHOLD = 60

S3IndexType = TypeVar('S3IndexType', bound='S3Index')


@dataclasses.dataclass(frozen=False)
@functools.total_ordering
class S3Object:
    key: str
    orig_key: str
    checksum: Optional[str]
    size: Optional[int]

    def __hash__(self):
        return hash(self.key)

    def __str__(self):
        return self.key

    def __eq__(self, other):
        return self.key == other.key

    def __lt__(self, other):
        return self.key < other.key


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


def safe_parse_version(ver_str: str) -> Version:
    try:
        return _parse_version(ver_str)
    except InvalidVersion:
        return Version("0.0.0")



class S3Index:
    def __init__(self: S3IndexType, objects: List[S3Object], prefix: str) -> None:
        self.objects = objects
        self.prefix = prefix.rstrip("/")
        self.html_name = PREFIXES_WITH_HTML[self.prefix]
        # should dynamically grab subdirectories like whl/test/cu101
        # so we don't need to add them manually anymore
        self.subdirs = {
            path.dirname(obj.key) for obj in objects if path.dirname != prefix
        }

    def nightly_packages_to_show(self: S3IndexType) -> List[S3Object]:
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
            key=lambda name_ver: safe_parse_version(name_ver.split('-', 1)[-1]),
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
            if packages[package_name] >= KEEP_THRESHOLD or between_bad_dates(package_build_time):
                to_hide.add(obj)
            else:
                packages[package_name] += 1
        return list(set(self.objects).difference({
            obj for obj in self.objects
            if self.normalize_package_version(obj) in to_hide
        }))

    def is_obj_at_root(self, obj: S3Object) -> bool:
        return path.dirname(obj.key) == self.prefix

    def _resolve_subdir(self, subdir: Optional[str] = None) -> str:
        if not subdir:
            subdir = self.prefix
        # make sure we strip any trailing slashes
        return subdir.rstrip("/")

    def gen_file_list(
        self,
        subdir: Optional[str] = None,
        package_name: Optional[str] = None
    ) -> Iterable[S3Object]:
        objects = self.objects
        subdir = self._resolve_subdir(subdir) + '/'
        for obj in objects:
            if package_name is not None and self.obj_to_package_name(obj) != package_name:
                continue
            if self.is_obj_at_root(obj) or obj.key.startswith(subdir):
                yield obj

    def get_package_names(self, subdir: Optional[str] = None) -> List[str]:
        return sorted({self.obj_to_package_name(obj) for obj in self.gen_file_list(subdir)})

    def normalize_package_version(self: S3IndexType, obj: S3Object) -> str:
        # removes the GPU specifier from the package name as well as
        # unnecessary things like the file extension, architecture name, etc.
        return sub(
            r"%2B.*",
            "",
            "-".join(path.basename(obj.key).split("-")[:2])
        )

    def obj_to_package_name(self, obj: S3Object) -> str:
        return path.basename(obj.key).split('-', 1)[0]

    def to_legacy_html(
        self,
        subdir: Optional[str] = None
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
            sanitized_obj = obj.key.replace(subdir, "", 1)
            if sanitized_obj.startswith('/'):
                sanitized_obj = sanitized_obj.lstrip("/")
            # we include objects at our root prefix so that users can still
            # install packages like torchaudio / torchtext even if they want
            # to install a specific GPU arch of torch / torchvision
            if not is_root and self.is_obj_at_root(obj):
                # strip root prefix
                sanitized_obj = obj.key.replace(self.prefix, "", 1).lstrip("/")
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
        out.append('    <h1>Links for {}</h1>'.format(package_name.lower().replace("_", "-")))
        for obj in sorted(self.gen_file_list(subdir, package_name)):
            maybe_fragment = f"#sha256={obj.checksum}" if obj.checksum else ""
            out.append(f'    <a href="/{obj.key}{maybe_fragment}">{path.basename(obj.key).replace("%2B","+")}</a><br/>')
        # Adding html footer
        out.append('  </body>')
        out.append('</html>')
        out.append(f'<!--TIMESTAMP {int(time.time())}-->')
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
            out.append(f'    <a href="{pkg_name.lower().replace("_","-")}/">{pkg_name.replace("_","-")}</a><br/>')
        # Adding html footer
        out.append('  </body>')
        out.append('</html>')
        out.append(f'<!--TIMESTAMP {int(time.time())}-->')
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

    def compute_sha256(self) -> None:
        for obj in self.objects:
            if obj.checksum is not None:
                continue
            print(f"Updating {obj.orig_key} of size {obj.size} with SHA256 checksum")
            s3_obj = BUCKET.Object(key=obj.orig_key)
            s3_obj.copy_from(CopySource={"Bucket": BUCKET.name, "Key": obj.orig_key},
                             Metadata=s3_obj.metadata, MetadataDirective="REPLACE",
                             ACL="public-read",
                             ChecksumAlgorithm="SHA256")

    @classmethod
    def has_public_read(cls: Type[S3IndexType], key: str) -> bool:
        def is_all_users_group(o) -> bool:
            return o.get("Grantee", {}).get("URI") == "http://acs.amazonaws.com/groups/global/AllUsers"

        def can_read(o) -> bool:
            return o.get("Permission") in ["READ", "FULL_CONTROL"]

        acl_grants = CLIENT.get_object_acl(Bucket=BUCKET.name, Key=key)["Grants"]
        return any(is_all_users_group(x) and can_read(x) for x in acl_grants)

    @classmethod
    def grant_public_read(cls: Type[S3IndexType], key: str) -> None:
        CLIENT.put_object_acl(Bucket=BUCKET.name, Key=key, ACL="public-read")

    @classmethod
    def fetch_object_names(cls: Type[S3IndexType], prefix: str) -> List[str]:
        obj_names = []
        for obj in BUCKET.objects.filter(Prefix=prefix):
            is_acceptable = any([path.dirname(obj.key) == prefix] + [
                match(
                    f"{prefix}/{pattern}",
                    path.dirname(obj.key)
                )
                for pattern in ACCEPTED_SUBDIR_PATTERNS
            ]) and obj.key.endswith(ACCEPTED_FILE_EXTENSIONS)
            if not is_acceptable:
                continue
            obj_names.append(obj.key)
        return obj_names

    def fetch_metadata(self: S3IndexType) -> None:
        # Add PEP 503-compatible hashes to URLs to allow clients to avoid spurious downloads, if possible.
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
            for idx, future in {
                idx: executor.submit(
                    lambda key: CLIENT.head_object(
                        Bucket=BUCKET.name, Key=key, ChecksumMode="Enabled"
                    ),
                    obj.orig_key,
                )
                for (idx, obj) in enumerate(self.objects)
                if obj.size is None
            }.items():
                response = future.result()
                sha256 = (_b64 := response.get("ChecksumSHA256")) and base64.b64decode(_b64).hex()
                # For older files, rely on checksum-sha256 metadata that can be added to the file later
                if sha256 is None:
                    sha256 = response.get("Metadata", {}).get("checksum-sha256")
                self.objects[idx].checksum = sha256
                if size := response.get("ContentLength"):
                    self.objects[idx].size = int(size)

    @classmethod
    def from_S3(cls: Type[S3IndexType], prefix: str, with_metadata: bool = True) -> S3IndexType:
        prefix = prefix.rstrip("/")
        obj_names = cls.fetch_object_names(prefix)

        def sanitize_key(key: str) -> str:
            return key.replace("+", "%2B")

        rc = cls([S3Object(key=sanitize_key(key),
                           orig_key=key,
                           checksum=None,
                           size=None) for key in obj_names], prefix)
        if prefix == "whl/nightly":
           rc.objects = rc.nightly_packages_to_show()
        if with_metadata:
            rc.fetch_metadata()
        return rc

    @classmethod
    def undelete_prefix(cls: Type[S3IndexType], prefix: str) -> None:
        paginator = CLIENT.get_paginator("list_object_versions")
        for page in paginator.paginate(Bucket=BUCKET.name, Prefix=prefix):
            for obj in page.get("DeleteMarkers", []):
                if not obj.get("IsLatest"):
                    continue
                obj_key, obj_version_id = obj["Key"], obj["VersionId"]
                obj_ver = S3.ObjectVersion(BUCKET.name, obj_key, obj_version_id)
                print(f"Undeleting {obj_key} deleted on {obj['LastModified']}")
                obj_ver.delete()


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser("Manage S3 HTML indices for PyTorch")
    parser.add_argument(
        "prefix",
        type=str,
        choices=list(PREFIXES_WITH_HTML.keys()) + ["all"]
    )
    parser.add_argument("--do-not-upload", action="store_true")
    parser.add_argument("--generate-pep503", action="store_true")
    parser.add_argument("--compute-sha256", action="store_true")
    return parser


def main() -> None:
    parser = create_parser()
    args = parser.parse_args()
    action = "Saving indices" if args.do_not_upload else "Uploading indices"
    if args.compute_sha256:
        action = "Computing checksums"

    prefixes = PREFIXES_WITH_HTML if args.prefix == 'all' else [args.prefix]
    for prefix in prefixes:
        print(f"INFO: {action} for '{prefix}'")
        stime = time.time()
        idx = S3Index.from_S3(prefix=prefix, with_metadata=args.generate_pep503 or args.compute_sha256)
        etime = time.time()
        print(f"DEBUG: Fetched {len(idx.objects)} objects for '{prefix}' in {etime-stime:.2f} seconds")
        if args.compute_sha256:
            idx.compute_sha256()
        elif args.do_not_upload:
            idx.save_legacy_html()
            if args.generate_pep503:
                idx.save_pep503_htmls()
        else:
            idx.upload_legacy_html()
            if args.generate_pep503:
                idx.upload_pep503_htmls()


if __name__ == "__main__":
    main()
