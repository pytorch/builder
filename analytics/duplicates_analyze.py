#!/usr/bin/env python3
from typing import Dict, List
from subprocess import check_output
import os
import sys

def get_defined_symbols(fname: str) -> Dict[str, int]:
    if sys.platform == 'darwin':
        lines = check_output(['nm', '--defined-only', '-n', fname]).decode('ascii').split("\n")[:-1]
        rc = {}
        for idx, line in enumerate(lines):
            addr, stype, name = line.split(" ")
            size = 4 if idx + 1 == len(lines)  else (int(lines[idx+1].split(" ")[0], 16) - int(addr, 16))
            rc[name] = size
        return rc
    lines = check_output(['nm', '--print-size', '--defined-only', fname]).decode('ascii').split("\n")
    return {e[3]:int(e[1], 16) for e in [l.split() for l in lines] if len(e) == 4}


def get_deps(fname: str) -> List[str]:
    if sys.platform == 'darwin':
        rc = []
        lines = check_output(['otool', '-l', fname]).decode('ascii').split("\n")[1:-1]
        for idx, line in enumerate(lines):
            if line.strip() != 'cmd LC_LOAD_DYLIB':
                continue
            path = lines[idx+2].strip()
            assert path.startswith('name')
            rc.append(os.path.basename(path.split(" ")[1]))
        return rc
    lines = check_output(['readelf', '--dynamic', fname]).decode('ascii').split("\n")
    return [line.split("[")[1][:-1] for line in lines if '(NEEDED)' in line]

def humansize(size):
    if size < 1024:
        return f"{size} bytes"
    if size < 1024**2:
        return f"{int(size/1024)} Kb"
    if size < 1024**3:
        return f"{size/(1024.0**2):.2f} Mb"
    return f"{size/(1024.0**3):.2f} Gb"

def print_sizes(libname, depth: int = 2) -> None:
    libs = [libname]
    depth = 2
    print(f"Processing {libname}...", end='', flush=True)
    symbols = {os.path.basename(libname): get_defined_symbols(libname)}
    print("done")
    for _ in range(depth):
        for lib in libs:
            dirname = os.path.dirname(lib)
            for dep in get_deps(lib):
                path = os.path.join(dirname, dep)
                if not os.path.exists(path):
                    continue
                if path not in libs:
                    libs.append(path)
                    print(f"Processing {path}...", end='', flush=True)
                    symbols[dep] = get_defined_symbols(path)
                    print("done")

    for lib in libs:
        lib_symbols = symbols[os.path.basename(lib)]
        lib_keys = set(lib_symbols.keys())
        rc = f"{lib} symbols size {humansize(sum(lib_symbols.values()))}"
        for dep in get_deps(lib):
            if dep not in symbols:
                continue
            dep_overlap = lib_keys.intersection(set(symbols[dep].keys()))
            overlap_size = sum(lib_symbols[k] for k in dep_overlap)
            if overlap_size > 0:
                rc += f" {dep} overlap is {humansize(overlap_size)}"
        print(rc)

if __name__ == '__main__':
    print_sizes(sys.argv[1] if len(sys.argv)>1 else "lib/libtorch_cuda.so")
