#!/usr/bin/env python3

import os
import subprocess
from typing import Dict, List, Optional, Tuple, Union



def list_dir(path: str) -> List[str]:
     return os.system(["ls", "-1", path]).split("\n")


def build_OpenBLAS(git_clone_flags: str = "") -> None:
    print('Building OpenBLAS')
    os.system(f"cd /; git clone https://github.com/xianyi/OpenBLAS -b v0.3.21 {git_clone_flags}")
    make_flags = "NUM_THREADS=64 USE_OPENMP=1 NO_SHARED=1 DYNAMIC_ARCH=1 TARGET=ARMV8"
    os.system(f"cd OpenBLAS; make {make_flags} -j8; make {make_flags} install; cd /; rm -rf OpenBLAS")


def build_ArmComputeLibrary(git_clone_flags: str = "") -> None:
    print('Building Arm Compute Library')
    os.system("cd / && mkdir /acl")
    os.system(f"git clone https://github.com/ARM-software/ComputeLibrary.git -b v22.11 {git_clone_flags}")
    os.system(f"cd ComputeLibrary; export acl_install_dir=/acl; " \
                f"scons Werror=1 -j8 debug=0 neon=1 opencl=0 os=linux openmp=1 cppthreads=0 arch=armv8.2-a multi_isa=1 build=native build_dir=$acl_install_dir/build; " \
                f"cp -r arm_compute $acl_install_dir; " \
                f"cp -r include $acl_install_dir; " \
                f"cp -r utils $acl_install_dir; " \
                f"cp -r support $acl_install_dir; " \
                f"cp -r src $acl_install_dir; cd /")


def embed_libgomp(use_conda, wheel_name) -> None:
    os.system("pip3 install auditwheel")
    os.system("conda install -y patchelf")
    from tempfile import NamedTemporaryFile
    with NamedTemporaryFile() as tmp:
        tmp.write(embed_library_script.encode('utf-8'))
        tmp.flush()
        os.system(f"mv {tmp.name} ./embed_library.py")

    print('Embedding libgomp into wheel')
    os.system(f"python3 embed_library.py {wheel_name} --update-tag")


def checkout_repo(branch: str = "master",
                  url: str = "",
                  git_clone_flags: str = "",
                  mapping: Dict[str, Tuple[str, str]] = []) -> Optional[str]:
    for prefix in mapping:
        if not branch.startswith(prefix):
            continue
        tag = f"v{mapping[prefix][0]}-{mapping[prefix][1]}"
        os.system(f"git clone {url} -b {tag} {git_clone_flags}")
        return mapping[prefix][0]

    os.system(f"git clone {url} {git_clone_flags}")
    return None


def build_torchvision(branch: str = "main",
                      use_conda: bool = True,
                      git_clone_flags: str = "") -> str:
    print('Checking out TorchVision repo')
    build_version = checkout_repo(branch=branch,
                                  url="https://github.com/pytorch/vision",
                                  git_clone_flags=git_clone_flags,
                                  mapping={
                                      "v1.7.1": ("0.8.2", "rc2"),
                                      "v1.8.0": ("0.9.0", "rc3"),
                                      "v1.8.1": ("0.9.1", "rc1"),
                                      "v1.9.0": ("0.10.0", "rc1"),
                                      "v1.10.0": ("0.11.1", "rc1"),
                                      "v1.10.1": ("0.11.2", "rc1"),
                                      "v1.10.2": ("0.11.3", "rc1"),
                                      "v1.11.0": ("0.12.0", "rc1"),
                                      "v1.12.0": ("0.13.0", "rc4"),
                                      "v1.12.1": ("0.13.1", "rc6"),
                                      "v1.13.0": ("0.14.0", "rc4"),
                                      "v1.13.1": ("0.14.1", "rc2"),
                                  })
    print('Building TorchVision wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    if branch == 'nightly':
        version = os.system(["if [ -f vision/version.txt ]; then cat vision/version.txt; fi"]).strip()
        if len(version) == 0:
            # In older revisions, version was embedded in setup.py
            version = os.system(["grep", "\"version = '\"", "vision/setup.py"]).strip().split("'")[1][:-2]
        build_date = os.system("cd /pytorch ; git log --pretty=format:%s -1").strip().split()[0].replace("-", "")
        build_vars += f"BUILD_VERSION={version}.dev{build_date}"
    elif build_version is not None:
        build_vars += f"BUILD_VERSION={build_version}"

    os.system(f"cd /vision; {build_vars} python3 setup.py bdist_wheel")
    wheel_name = os.system("ls /vision/dist")[0]
    embed_libgomp(use_conda, os.path.join('vision', 'dist', wheel_name))

    print('Move TorchVision wheel to artfacts')
    os.system(f"mv /vision/dist/{wheel_name} /artifacts/")
    return wheel_name


def build_torchtext(branch: str = "main",
                    use_conda: bool = True,
                    git_clone_flags: str = "") -> str:
    print('Checking out TorchText repo')
    os.system(f"cd /")
    git_clone_flags += " --recurse-submodules"
    build_version = checkout_repo(branch=branch,
                                  url="https://github.com/pytorch/text",
                                  git_clone_flags=git_clone_flags,
                                  mapping={
                                      "v1.9.0": ("0.10.0", "rc1"),
                                      "v1.10.0": ("0.11.0", "rc2"),
                                      "v1.10.1": ("0.11.1", "rc1"),
                                      "v1.10.2": ("0.11.2", "rc1"),
                                      "v1.11.0": ("0.12.0", "rc1"),
                                      "v1.12.0": ("0.13.0", "rc2"),
                                      "v1.12.1": ("0.13.1", "rc5"),
                                      "v1.13.0": ("0.14.0", "rc3"),
                                      "v1.13.1": ("0.14.1", "rc1"),
                                  })
    print('Building TorchText wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    if branch == 'nightly':
        version = os.system(["if [ -f text/version.txt ]; then cat text/version.txt; fi"]).strip()
        build_date = os.system("cd pytorch ; git log --pretty=format:%s -1").strip().split()[0].replace("-", "")
        build_vars += f"BUILD_VERSION={version}.dev{build_date}"
    elif build_version is not None:
        build_vars += f"BUILD_VERSION={build_version}"

    os.system(f"cd text; {build_vars} python3 setup.py bdist_wheel")
    wheel_name = os.system("ls /text/dist")[0]
    embed_libgomp(use_conda, os.path.join('text', 'dist', wheel_name))

    print('Move TorchText wheel to artfacts')
    os.system(f"mv /text/dist/{wheel_name} /artifacts/")
    return wheel_name


def build_torchaudio(branch: str = "main",
                     use_conda: bool = True,
                     git_clone_flags: str = "") -> str:
    print('Checking out TorchAudio repo')
    git_clone_flags += " --recurse-submodules"
    build_version = checkout_repo(branch=branch,
                                  url="https://github.com/pytorch/audio",
                                  git_clone_flags=git_clone_flags,
                                  mapping={
                                      "v1.9.0": ("0.9.0", "rc2"),
                                      "v1.10.0": ("0.10.0", "rc5"),
                                      "v1.10.1": ("0.10.1", "rc1"),
                                      "v1.10.2": ("0.10.2", "rc1"),
                                      "v1.11.0": ("0.11.0", "rc1"),
                                      "v1.12.0": ("0.12.0", "rc3"),
                                      "v1.12.1": ("0.12.1", "rc5"),
                                      "v1.13.0": ("0.13.0", "rc4"),
                                      "v1.13.1": ("0.13.1", "rc2"),
                                  })
    print('Building TorchAudio wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    if branch == 'nightly':
        version = os.system(["grep", "\"version = '\"", "audio/setup.py"]).strip().split("'")[1][:-2]
        build_date = os.system("cd pytorch ; git log --pretty=format:%s -1").strip().split()[0].replace("-", "")
        build_vars += f"BUILD_VERSION={version}.dev{build_date}"
    elif build_version is not None:
        build_vars += f"BUILD_VERSION={build_version}"

    os.system(f"cd /audio; {build_vars} python3 setup.py bdist_wheel")
    wheel_name = os.system("ls /audio/dist")[0]
    embed_libgomp(use_conda, os.path.join('audio', 'dist', wheel_name))

    print('Move TorchAudio wheel to artfacts')
    os.system(f"mv /audio/dist/{wheel_name} /artifacts/")
    return wheel_name


def build_torchdata(branch: str = "main",
                     use_conda: bool = True,
                     git_clone_flags: str = "") -> str:
    print('Checking out TorchData repo')
    git_clone_flags += " --recurse-submodules"
    build_version = checkout_repo(branch=branch,
                                  url="https://github.com/pytorch/data",
                                  git_clone_flags=git_clone_flags,
                                  mapping={
                                      "v1.11.0": ("0.3.0", "rc1"),
                                      "v1.12.0": ("0.4.0", "rc3"),
                                      "v1.12.1": ("0.4.1", "rc5"),
                                      "v1.13.1": ("0.5.1", "rc2"),
                                  })
    print('Building TorchData wheel')
    build_vars = "CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    if branch == 'nightly':
        version = os.system(["grep", "\"version = '\"", "audio/setup.py"]).strip().split("'")[1][:-2]
        build_date = os.system("cd /pytorch ; git log --pretty=format:%s -1").strip().split()[0].replace("-", "")
        build_vars += f"BUILD_VERSION={version}.dev{build_date}"
    elif build_version is not None:
        build_vars += f"BUILD_VERSION={build_version}"

    os.system(f"cd /data; {build_vars} python3 setup.py bdist_wheel")
    wheel_name = os.system("ls /data/dist")[0]
    embed_libgomp(use_conda, os.path.join('data', 'dist', wheel_name))

    print('Move TorchAudio wheel to artfacts')
    os.system(f"mv /data/dist/{wheel_name} /artifacts/")
    return wheel_name


def start_build(branch="master",
                compiler="gcc-8",
                use_conda=True,
                python_version="3.8",
                shallow_clone=True,
                enable_mkldnn=False) -> Tuple[str, str]:
    git_clone_flags = " --depth 1 --shallow-submodules" if shallow_clone else ""
    os.system(f"conda install -y ninja scons")

    print("Build and Install OpenBLAS")
    build_OpenBLAS(git_clone_flags)

    print('Building PyTorch wheel')
    # Breakpad build fails on aarch64
    build_vars = "USE_BREAKPAD=0 CMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=0x10000 "
    os.system(f"cd /pytorch; pip install -r requirements.txt")
    if branch == 'nightly':
        build_date = os.system("git log --pretty=format:%s -1").strip().split()[0].replace("-", "")
        version = os.system("cat /pytorch/version.txt").strip()[:-2]
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={version}.dev{build_date} PYTORCH_BUILD_NUMBER=1"
    if branch.startswith("v1."):
        build_vars += f"BUILD_TEST=0 PYTORCH_BUILD_VERSION={branch[1:branch.find('-')]} PYTORCH_BUILD_NUMBER=1"
    if enable_mkldnn:
        build_ArmComputeLibrary(git_clone_flags)
        print("build pytorch with mkldnn+acl backend")
        os.system(f"export ACL_ROOT_DIR=/acl; export LD_LIBRARY_PATH=/acl/build; export ACL_LIBRARY=/acl/build")
        build_vars += " USE_MKLDNN=ON USE_MKLDNN_ACL=ON"
        os.system(f"cd /pytorch; {build_vars} python3 setup.py bdist_wheel")
        print('Repair the wheel')
        pytorch_wheel_name = list_dir("pytorch/dist")[0]
        os.system(f"export LD_LIBRARY_PATH=/pytorch/build/lib:$LD_LIBRARY_PATH; auditwheel repair /pytorch/dist/{pytorch_wheel_name}")
        print('replace the original wheel with the repaired one')
        pytorch_repaired_wheel_name = list_dir("wheelhouse")[0]
        os.system(f"cp /wheelhouse/{pytorch_repaired_wheel_name} /pytorch/dist/{pytorch_wheel_name}")
    else:
        print("build pytorch without mkldnn backend")
        os.system(f"cd pytorch ; {build_vars} python3 setup.py bdist_wheel")

    print("Deleting build folder")
    os.system("cd /pytorch; rm -rf build")
    pytorch_wheel_name = os.system("ls /pytorch/dist")[0]
    embed_libgomp(use_conda, os.path.join('pytorch', 'dist', pytorch_wheel_name))
    print('Move PyTorch wheel to artfacts')
    os.system(f"mv /pytorch/dist/{pytorch_wheel_name} /artifacts/")

    vision_wheel_name = build_torchvision(branch=branch, use_conda=use_conda, git_clone_flags=git_clone_flags)
    audio_wheel_name = build_torchaudio(branch=branch, use_conda=use_conda, git_clone_flags=git_clone_flags)
    text_wheel_name = build_torchtext(branch=branch, use_conda=use_conda, git_clone_flags=git_clone_flags)
    data_wheel_name = build_torchdata(branch=branch, use_conda=use_conda, git_clone_flags=git_clone_flags)
    return [pytorch_wheel_name, vision_wheel_name, audio_wheel_name, text_wheel_name, data_wheel_name]


embed_library_script = """
#!/usr/bin/env python3

from auditwheel.patcher import Patchelf
from auditwheel.wheeltools import InWheelCtx
from auditwheel.elfutils import elf_file_filter
from auditwheel.repair import copylib
from auditwheel.lddtree import lddtree
from subprocess import check_call
import os
import shutil
import sys
from tempfile import TemporaryDirectory


def replace_tag(filename):
   with open(filename, 'r') as f:
     lines = f.read().split("\\n")
   for i,line in enumerate(lines):
       if not line.startswith("Tag: "):
           continue
       lines[i] = line.replace("-linux_", "-manylinux2014_")
       print(f'Updated tag from {line} to {lines[i]}')

   with open(filename, 'w') as f:
       f.write("\\n".join(lines))


class AlignedPatchelf(Patchelf):
    def set_soname(self, file_name: str, new_soname: str) -> None:
        check_call(['patchelf', '--page-size', '65536', '--set-soname', new_soname, file_name])

    def replace_needed(self, file_name: str, soname: str, new_soname: str) -> None:
        check_call(['patchelf', '--page-size', '65536', '--replace-needed', soname, new_soname, file_name])


def embed_library(whl_path, lib_soname, update_tag=False):
    patcher = AlignedPatchelf()
    out_dir = TemporaryDirectory()
    whl_name = os.path.basename(whl_path)
    tmp_whl_name = os.path.join(out_dir.name, whl_name)
    with InWheelCtx(whl_path) as ctx:
        torchlib_path = os.path.join(ctx._tmpdir.name, 'torch', 'lib')
        ctx.out_wheel=tmp_whl_name
        new_lib_path, new_lib_soname = None, None
        for filename, elf in elf_file_filter(ctx.iter_files()):
            if not filename.startswith('torch/lib'):
                continue
            libtree = lddtree(filename)
            if lib_soname not in libtree['needed']:
                continue
            lib_path = libtree['libs'][lib_soname]['path']
            if lib_path is None:
                print(f"Can't embed {lib_soname} as it could not be found")
                break
            if lib_path.startswith(torchlib_path):
                continue

            if new_lib_path is None:
                new_lib_soname, new_lib_path = copylib(lib_path, torchlib_path, patcher)
            patcher.replace_needed(filename, lib_soname, new_lib_soname)
            print(f'Replacing {lib_soname} with {new_lib_soname} for {filename}')
        if update_tag:
            # Add manylinux2014 tag
            for filename in ctx.iter_files():
                if os.path.basename(filename) != 'WHEEL':
                    continue
                replace_tag(filename)
    shutil.move(tmp_whl_name, whl_path)


if __name__ == '__main__':
    embed_library(sys.argv[1], 'libgomp.so.1', len(sys.argv) > 2 and sys.argv[2] == '--update-tag')
"""

def parse_arguments():
    from argparse import ArgumentParser
    parser = ArgumentParser("AARCH64 wheels python CD")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--build-only", action="store_true")
    parser.add_argument("--test-only", type=str)
    parser.add_argument("--python-version", type=str, choices=['3.6', '3.7', '3.8', '3.9', '3.10'], default=None)
    parser.add_argument("--branch", type=str, default="master")
    parser.add_argument("--compiler", type=str, choices=['gcc-7', 'gcc-8', 'gcc-9', 'clang'], default="gcc-8")
    parser.add_argument("--enable-mkldnn", action="store_true")
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_arguments()

    start_build(branch=args.branch,
                compiler=args.compiler,
                python_version=args.python_version,
                enable_mkldnn=args.enable_mkldnn)
