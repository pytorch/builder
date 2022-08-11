from conda.cli.python_api import Commands, run_command
from tabulate import tabulate
from datetime import datetime
import json

PLATFORMS = ["osx-64", "linux-64", "win-64"]
PYTHON_VERSIONS = ["3.10", "3.9", "3.8", "3.7"]
CUDA_CUDNN_VERSION = [
    ("11.5", "8.3.2"), ("11.3", "8.2.0"), ("11.1", "8.0.5"), ("10.2", "7.6.5"), ("cpu", None)
]
CHANNEL = "pytorch-test"
VERSION = "1.11.*"


def generate_expected_builds(platform: str) -> set:
    builds = set()
    for py_version in PYTHON_VERSIONS:
        if platform == "osx-64":
            # macos builds support cpu only.
            builds.add(f"py{py_version}_0")
            continue

        for cuda_version, cudnn_version in CUDA_CUDNN_VERSION:
            if platform == "win-64":
                if cuda_version == "10.2":
                    # win does not support cuda 10.2
                    continue
                cudnn_version = "8"

            if cuda_version == "cpu":
                builds.add(f"py{py_version}_{cuda_version}_0")
            else:
                builds.add(f"py{py_version}_cuda{cuda_version}_cudnn{cudnn_version}_0")
    return builds


def size_format(size_num) -> str:
    for unit in ["", "K", "M", "G"]:
        if abs(size_num) < 1024.0:
            return f"{size_num:3.1f}{unit}B"

        size_num /= 1024.0
    return f"{size_num:3.1f}TB"


def main() -> None:
    # Iterate over platform to gather build information of available conda version.
    for platform in PLATFORMS:
        expected_builds = generate_expected_builds(platform)

        # Actual builds available in Conda
        stdout, stderr, return_code = run_command(
            Commands.SEARCH, f"{CHANNEL}::*[name=pytorch version={VERSION} subdir={platform}]", "--json")

        if return_code != 0:
            raise Exception(stderr)

        available_versions = json.loads(stdout)
        output_data = []
        headers = ["File Name", "Date", "Size"]
        actual_builds = set()
        for version in available_versions["pytorch"]:
            actual_builds.add(version["build"])
            output_data.append((
                version["fn"],
                datetime.fromtimestamp(version["timestamp"] / 1000),
                size_format(version["size"])
            ))

        assert len(expected_builds) > 0, "expected builds set should not be empty."
        assert expected_builds == actual_builds, (
            f"Missing following builds in conda: {expected_builds.difference(actual_builds)} for platform {platform}"
        )

        print(f"\nSuccessfully verified following binaries are available in Conda for {platform}...")
        print(tabulate(output_data, headers=headers, tablefmt="grid"))


if __name__ == "__main__":
    main()
