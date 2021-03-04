#!/usr/bin/env python3
# Tool for analyzing sizes of CUDA kernels for various GPU architectures
import os
import struct
import subprocess
import sys
from tempfile import TemporaryDirectory
from typing import Dict


# Try to auto-import elftools
try:
    from elftools.elf.elffile import ELFFile
except ModuleNotFoundError:
    print(f'elftools module not found, trying to install it from pip')
    from pip._internal import main as pip_main
    try:
        pip_main(["install", "pyelftools", "--user"])
    except SystemExit:
        print(f'PIP installation failed, please install it manually by invoking "{sys.executable} -mpip install pyelftools --user"')
        sys.exit(-1)
    from elftools.elf.elffile import ELFFile


# From https://stackoverflow.com/questions/1094841/reusable-library-to-get-human-readable-version-of-file-size
def sizeof_fmt(num, suffix='B'):
    for unit in ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)


def compute_cubin_sizes(file_name, section_name='.nv_fatbin', debug=False):
    with open(file_name, 'rb') as f:
        elf_file = ELFFile(f)
        nv_fatbin = elf_file.get_section_by_name(section_name)
        if nv_fatbin is None:
            return {}
        data = nv_fatbin.data()
        idx, offs = 0, 0
        elf_sizes = {}
        while offs < len(data):
            (magic, version, header_size, fatbin_size) = struct.unpack('IHHL', data[offs: offs + 16])
            if magic != 0xba55ed50 or version != 1:
                raise RuntimeError(f"Unexpected fatbin magic {hex(magic)} or version {version}")
            if debug:
                print(f"Found fatbin at {offs}  header_size={header_size} fatbin_size={fatbin_size}")
            offs += header_size
            fatbin_end = offs + fatbin_size
            while offs < fatbin_end:
                (kind, version, hdr_size, elf_size, empty, code_ver, sm_ver) = struct.unpack('HHILLIH', data[offs: offs + 30])
                if version != 0x0101 or kind not in [1, 2]:
                    raise RuntimeError(f"Unexpected cubin version {hex(version)} or kind {kind}")
                sm_ver = f'{"ptx" if kind == 1 else "sm"}_{sm_ver}'
                if debug:
                    print(f"    {idx}: elf_size={elf_size} code_ver={hex(code_ver)} sm={sm_ver}")
                if sm_ver not in elf_sizes:
                    elf_sizes[sm_ver] = 0
                elf_sizes[sm_ver] += elf_size
                idx, offs = idx + 1, offs + hdr_size + elf_size
            offs = fatbin_end
        return elf_sizes


class ArFileCtx:
    def __init__(self, ar_name: str) -> None:
        self.ar_name = os.path.abspath(ar_name)
        self._tmpdir = TemporaryDirectory()

    def __enter__(self) -> str:
        self._pwd = os.getcwd()
        rc = self._tmpdir.__enter__()
        subprocess.check_call(['ar', 'x', self.ar_name])
        return rc

    def __exit__(self, ex, value, tb) -> None:
        os.chdir(self._pwd)
        return self._tmpdir.__exit__(ex, value, tb)


def dict_add(rc: Dict[str, int], b: Dict[str, int]) -> Dict[str, int]:
    for key, val in b.items():
        rc[key] = (rc[key] if key in rc else 0) + val
    return rc


def main():
    if sys.platform != 'linux':
        print('This script only works with Linux ELF files')
        return
    if len(sys.argv) < 2:
        print(f"{sys.argv[0]} invoked without any arguments trying to infer location of libtorch_cuda")
        import torch
        fname = os.path.join(os.path.dirname(torch.__file__), 'lib', 'libtorch_cuda.so')
    else:
        fname = sys.argv[1]

    if not os.path.exists(fname):
        print(f"Can't find {fname}")
        sys.exit(-1)

    section_names = ['.nv_fatbin', '__nv_relfatbin']
    results = {name: {} for name in section_names}
    print(f"Analyzing {fname}")
    if os.path.splitext(fname)[1] == '.a':
        with ArFileCtx(fname):
            for fname in os.listdir("."):
                if not fname.endswith(".o"): continue
                for section_name in section_names:
                    elf_sizes = compute_cubin_sizes(fname, section_name)
                    dict_add(results[section_name], elf_sizes)
    else:
        for section_name in ['.nv_fatbin', '__nv_relfatbin']:
            dict_add(results[section_name], compute_cubin_sizes(fname, section_name))

    for section_name in section_names:
        elf_sizes = results[section_name]
        print(f"{section_name} size {sizeof_fmt(sum(elf_sizes.values()))}")
        for (sm_ver, total_size) in elf_sizes.items():
            print(f"  {sm_ver}: {sizeof_fmt(total_size)}")


if __name__ == '__main__':
    main()
