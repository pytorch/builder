#!/usr/bin/env python3
import concurrent.futures
import distutils.sysconfig
import itertools
import functools
import os
import re
from pathlib import Path

# We also check that there are [not] cxx11 symbols in libtorch
#
# To check whether it is using cxx11 ABI, check non-existence of symbol:
PRE_CXX11_SYMBOLS=(
  "std::basic_string<",
  "std::list",
)
# To check whether it is using pre-cxx11 ABI, check non-existence of symbol:
CXX11_SYMBOLS=(
  "std::__cxx11::basic_string",
  "std::__cxx11::list",
)
# NOTE: Checking the above symbols in all namespaces doesn't work, because
# devtoolset7 always produces some cxx11 symbols even if we build with old ABI,
# and CuDNN always has pre-cxx11 symbols even if we build with new ABI using gcc 5.4.
# Instead, we *only* check the above symbols in the following namespaces:
LIBTORCH_NAMESPACE_LIST=(
  "c10::",
  "at::",
  "caffe2::",
  "torch::",
)

LIBTORCH_CXX11_PATTERNS = [re.compile(f"{x}.*{y}") for (x,y) in itertools.product(LIBTORCH_NAMESPACE_LIST, CXX11_SYMBOLS)]

LIBTORCH_PRE_CXX11_PATTERNS = [re.compile(f"{x}.*{y}") for (x,y) in itertools.product(LIBTORCH_NAMESPACE_LIST, PRE_CXX11_SYMBOLS)]

@functools.lru_cache
def get_symbols(lib :str ) -> list[tuple[str, str, str]]:
  from subprocess import check_output
  lines = check_output(f'nm "{lib}"|c++filt', shell=True)
  return [x.split(' ', 2) for x in lines.decode('latin1').split('\n')[:-1]]


def count_symbols(lib: str, patterns: list[re.Match]) -> int:
    def _count_symbols(symbols: list[tuple[str, str, str]], patterns: list[str]) -> int:
        rc = 0
        for s_addr, s_type, s_name in symbols:
            for pattern in patterns:
                if pattern.match(s_name):
                    rc += 1
        return rc
    all_symbols = get_symbols(lib)
    num_workers= 32
    chunk_size = (len(all_symbols) + num_workers - 1 ) // num_workers
    with concurrent.futures.ThreadPoolExecutor(max_workers=32) as executor:
        tasks = [executor.submit(_count_symbols, all_symbols[i * chunk_size : (i + 1) * chunk_size], patterns) for i in range(num_workers)]
        return sum(x.result() for x in tasks)

def check_lib_symbols_for_abi_correctness(lib: str, pre_cxx11_abi: bool = True) -> None:
    print(f"lib: {lib}")
    num_cxx11_symbols = count_symbols(lib, LIBTORCH_CXX11_PATTERNS)
    num_pre_cxx11_symbols = count_symbols(lib, LIBTORCH_PRE_CXX11_PATTERNS)
    if pre_cxx11_abi:
        if  num_cxx11_symbols > 0:
            raise RuntimeError("Found cxx11 symbols, but there shouldn't be any")
        if num_pre_cxx11_symbols < 1000:
            raise RuntimeError("Didn't find enough pre-cxx11 symbols.")
    else:
        if num_pre_cxx11_symbols > 0:
            raise RuntimeError("Found pre-cxx11 symbols, but there shouldn't be any")
        if num_cxx11_symbols < 100:
            raise RuntimeError("Didn't find enought cxx11 symbols")

def main() -> None:
    if os.getenv("PACKAGE_TYPE") == "libtorch":
       install_root = Path(__file__).parent.parent
    else:
       install_root = Path(distutils.sysconfig.get_python_lib()) / "torch"
    libtorch_cpu_path = install_root / "lib" / "libtorch_cpu.so"
    pre_cxx11_abi = "cxx11-abi" not in os.getenv("DESIRED_DEVTOOLSET", "")
    check_lib_symbols_for_abi_correctness(libtorch_cpu_path, pre_cxx11_abi)


if __name__ == "__main__":
   main()
