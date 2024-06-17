#!/usr/bin/env python3

import os.path
import shutil
import subprocess
import tempfile
import zipfile

import boto3
import botocore

PLATFORMS = [
    "manylinux1_x86_64",
    "manylinux2014_aarch64",
    "win_amd64",
    "macosx_11_0_arm64",
]
PYTHON_VERSIONS = [
    "cp38", 
    "cp39", 
    "cp310", 
    "cp311", 
    "cp312"
    ]
S3_PYPI_STAGING = "pytorch-backup"
PACKAGE_RELEASES = {
    "torch": "2.3.1",
    "torchvision": "0.18.1",
    "torchaudio": "2.3.1",
    "torchtext": "0.18.0",
    "executorch": "0.2.1"
}

PATTERN_V = "Version:"
PATTERN_RD = "Requires-Dist:"

s3 = boto3.client("s3")


def get_size(path):
    size = os.path.getsize(path)
    if size < 1024:
        return f"{size} bytes"
    elif size < pow(1024, 2):
        return f"{round(size/1024, 2)} KB"
    elif size < pow(1024, 3):
        return f"{round(size/(pow(1024,2)), 2)} MB"
    elif size < pow(1024, 4):
        return f"{round(size/(pow(1024,3)), 2)} GB"


def generate_expected_builds(platform: str, package: str, release: str) -> list:
    builds = []
    for py_version in PYTHON_VERSIONS:
        py_spec = f"{py_version}-{py_version}"
        platform_spec = platform

        if package == "torchtext" and (
            platform == "manylinux2014_aarch64" or py_version == "cp312"
        ):
            continue

        # strange macos file nameing
        if "macos" in platform:
            if package == "torch":
                py_spec = f"{py_version}-none"
            elif "macosx_10_9_x86_64" in platform:
                platform_spec = "macosx_10_13_x86_64"

        builds.append(
            f"{package}-{release}-pypi-staging/{package}-{release}-{py_spec}-{platform_spec}.whl"
        )

    return builds


def validate_file_metadata(build: str, package: str, version: str):
    temp_dir = tempfile.mkdtemp()
    tmp_file = f"{temp_dir}/{os.path.basename(build)}"
    s3.download_file(Bucket=S3_PYPI_STAGING, Key=build, Filename=tmp_file)
    print(f"Downloaded: {tmp_file}  {get_size(tmp_file)}")

    try:
        check_wheels = subprocess.run(
            ["check-wheel-contents", tmp_file, "--ignore", "W002,W009,W004"],
            capture_output=True,
            text=True,
            check=True,
            encoding="utf-8",
        )
        print(check_wheels.stdout)
        print(check_wheels.stderr)
    except subprocess.CalledProcessError as e:
        exit_code = e.returncode
        stderror = e.stderr
        print(exit_code, stderror)

    with zipfile.ZipFile(f"{temp_dir}/{os.path.basename(build)}", "r") as zip_ref:
        zip_ref.extractall(f"{temp_dir}")

    for i, line in enumerate(
        open(f"{temp_dir}/{package}-{version}.dist-info/METADATA")
    ):
        if line.startswith(PATTERN_V):
            print(f"{line}", end="")
            exttracted_version = line.removeprefix(PATTERN_V).strip()
            if version != exttracted_version:
                print(
                    f"FAILURE VERSION DOES NOT MATCH expected {version} got {exttracted_version}"
                )

        elif line.startswith(PATTERN_RD):
            print(f"{line}", end="")

    shutil.rmtree(temp_dir)


def main():
    expected_builds = dict.fromkeys(PACKAGE_RELEASES, [])

    # Iterate over platform to gather build information of available conda version.
    for package in PACKAGE_RELEASES:
        for platform in PLATFORMS:
            expected_builds[package] = expected_builds[
                package
            ] + generate_expected_builds(platform, package, PACKAGE_RELEASES[package])

    for package in PACKAGE_RELEASES:
        count = 0
        for build in expected_builds[package]:
            try:
                s3.head_object(Bucket=S3_PYPI_STAGING, Key=build)
                print(f"Validating filename {os.path.basename(build)}")
                validate_file_metadata(build, package, PACKAGE_RELEASES[package])
                count += 1
            except botocore.exceptions.ClientError as e:
                if e.response["Error"]["Code"] == "404":
                    print(f"FAILED 404 Error on {build}")
                elif e.response["Error"]["Code"] == "403":
                    print(f"FAILED Unauthorized Error on {build}")
                else:
                    print(f"Error on {build}")
        print(f"Package Validated {count} for {package}")


if __name__ == "__main__":
    main()
