#!/usr/bin/env python3
import json
import os
import argparse
import io
import sys
from pathlib import Path
from typing import Dict, Set, List, Iterable
from enum import Enum

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

class OperatingSystem(Enum):
    LINUX: str = "linux"
    WINDOWS: str = "windows"
    MACOS: str = "macos"

PRE_CXX11_ABI = "pre-cxx11"
CXX11_ABI = "cxx11-abi"
DEBUG = "debug"
RELEASE = "release"
DEFAULT = "default"
ENABLE = "enable"
DISABLE = "disable"

# Mapping json to release matrix is here for now
# TBD drive the mapping via:
#  1. Scanning release matrix and picking 2 latest cuda versions and 1 latest rocm
#  2. Possibility to override the scanning algorithm with arguments passed from workflow
acc_arch_map = {
        "accnone": ("cpu", ""),
        "cuda.x": ("cuda", "11.6"),
        "cuda.y": ("cuda", "11.7"),
        "rocm5.x": ("rocm", "5.2")
    }

LIBTORCH_DWNL_INSTR = {
        PRE_CXX11_ABI: "Download here (Pre-cxx11 ABI):",
        CXX11_ABI: "Download here (cxx11 ABI):",
        RELEASE: "Download here (Release version):",
        DEBUG: "Download here (Debug version):",
    }

def read_published_versions():
    with open(os.path.join(BASE_DIR, "published_versions.json")) as fp:
        return json.load(fp)

def write_published_versions(versions):
    with open(os.path.join(BASE_DIR, "published_versions.json"), "w") as outfile:
            json.dump(versions, outfile, indent=2)

def read_matrix_for_os(osys: OperatingSystem):
    try:
        with open(os.path.join(BASE_DIR, f"{osys.value}_matrix.json")) as fp:
            return json.load(fp)["include"]
    except FileNotFoundError as e:
        raise ImportError(f"Release matrix not found for: {osys.value} error: {e.strerror}") from e


def read_quick_start_module_template():
    with open(os.path.join(BASE_DIR, "_includes", "quick-start-module.js")) as fp:
        return fp.read()

def update_versions(versions, release_matrix, version):
    version_map = {
        "preview": "preview",
    }

    # Generating for a specific version
    if(version != "preview"):
        version_map = {
            version: version,
        }
        if version in versions["versions"]:
            if version != versions["latest_stable"]:
                raise RuntimeError(f"Can only update prview, latest stable: {versions['latest_stable']} or new version")
        else:
            import copy
            new_version = copy.deepcopy(versions["versions"]["preview"])
            versions["versions"][version] = new_version
            versions["latest_stable"] = version

    # Perform update of the json file from release matrix
    for ver, ver_key in version_map.items():
        for os_key, os_vers in versions["versions"][ver_key].items():
            for pkg_key, pkg_vers in os_vers.items():
                for acc_key, instr in pkg_vers.items():

                    package_type = pkg_key
                    if pkg_key == 'pip':
                        package_type = 'manywheel' if os_key == OperatingSystem.LINUX.value else 'wheel'

                    gpu_arch_type, gpu_arch_version = acc_arch_map[acc_key]
                    if(DEFAULT in instr):
                        gpu_arch_type, gpu_arch_version = acc_arch_map["accnone"]

                    pkg_arch_matrix = list(filter(
                            lambda x:
                            (x["package_type"], x["gpu_arch_type"], x["gpu_arch_version"]) ==
                            (package_type, gpu_arch_type, gpu_arch_version),
                            release_matrix[os_key]
                        ))

                    if pkg_arch_matrix:
                        if package_type != 'libtorch':
                            instr["command"] = pkg_arch_matrix[0]["installation"]
                        else:
                            if os_key == OperatingSystem.LINUX.value:
                                rel_entry_pre_cxx1 = next(filter(
                                    lambda x:
                                    x["devtoolset"] == PRE_CXX11_ABI,
                                    pkg_arch_matrix
                                ), None)
                                rel_entry_cxx1_abi = next(filter(
                                    lambda x:
                                    x["devtoolset"] == CXX11_ABI,
                                    pkg_arch_matrix
                                ), None)
                                if(instr['versions'] is not None):
                                    instr['versions'][LIBTORCH_DWNL_INSTR[PRE_CXX11_ABI]] = rel_entry_pre_cxx1["installation"]
                                    instr['versions'][LIBTORCH_DWNL_INSTR[CXX11_ABI]] = rel_entry_cxx1_abi["installation"]
                            elif os_key == OperatingSystem.WINDOWS.value:
                                rel_entry_release = next(filter(
                                    lambda x:
                                    x["libtorch_config"] == RELEASE,
                                    pkg_arch_matrix
                                ), None)
                                rel_entry_debug = next(filter(
                                    lambda x:
                                    x["libtorch_config"] == DEBUG,
                                    pkg_arch_matrix
                                ), None)
                                if(instr['versions'] is not None):
                                    instr['versions'][LIBTORCH_DWNL_INSTR[RELEASE]] = rel_entry_release["installation"]
                                    instr['versions'][LIBTORCH_DWNL_INSTR[DEBUG]] = rel_entry_debug["installation"]


def gen_install_matrix(versions) -> Dict[str, str]:
    rc = {}
    version_map = {
        "preview": "preview",
        "stable": versions["latest_stable"],
    }
    for ver, ver_key in version_map.items():
        for os_key, os_vers in versions["versions"][ver_key].items():
            for pkg_key, pkg_vers in os_vers.items():
                for acc_key, instr in pkg_vers.items():
                   extra_key = 'python' if pkg_key != 'libtorch' else 'cplusplus'
                   key = f"{ver},{pkg_key},{os_key},{acc_key},{extra_key}"
                   note = instr["note"]
                   lines = [note] if note is not None else []
                   if pkg_key == "libtorch":
                      ivers = instr["versions"]
                      if ivers is not None:
                          lines += [f"{lab}<br /><a href='{val}'>{val}</a>" for (lab, val) in ivers.items()]
                   else:
                       command = instr["command"]
                       if command is not None:
                           lines.append(command)
                   rc[key] = "<br />".join(lines)
    return rc


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--version",
        help="Version to generate the instructions for",
        type=str,
        default="1.13.0",
    )
    parser.add_argument(
        "--autogenerate",
        help="Is this call being initiated from workflow? update published_versions",
        type=str,
        choices=[ENABLE, DISABLE],
        default=ENABLE,
    )

    options = parser.parse_args()
    versions = read_published_versions()

    if options.autogenerate == ENABLE:
        release_matrix = {}
        for osys in OperatingSystem:
            release_matrix[osys.value] = read_matrix_for_os(osys)

        update_versions(versions, release_matrix, options.version)
        write_published_versions(versions)

    # template = read_quick_start_module_template()
    # versions_str = json.dumps(gen_install_matrix(versions))
    # print(template.replace("{{ installMatrix }}", versions_str))


if __name__ == "__main__":
    main()
