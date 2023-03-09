import os
import re
import sys
from pathlib import Path
import argparse
import torch
import platform
import importlib
import subprocess

gpu_arch_ver = os.getenv("MATRIX_GPU_ARCH_VERSION")
gpu_arch_type = os.getenv("MATRIX_GPU_ARCH_TYPE")
channel = os.getenv("MATRIX_CHANNEL")
stable_version = os.getenv("MATRIX_STABLE_VERSION")
package_type = os.getenv("MATRIX_PACKAGE_TYPE")

is_cuda_system = gpu_arch_type == "cuda"
SCRIPT_DIR = Path(__file__).parent
NIGHTLY_ALLOWED_DELTA = 3

MODULES = [
    {
        "name": "torchvision",
        "repo": "https://github.com/pytorch/vision.git",
        "smoke_test": "python ./vision/test/smoke_test.py",
        "extension": "extension",
    },
    {
        "name": "torchaudio",
        "repo": "https://github.com/pytorch/audio.git",
        "smoke_test": "python ./audio/test/smoke_test/smoke_test.py --no-ffmpeg",
        "extension": "_extension",
    },
]

def check_version(package: str) -> None:
    # only makes sense to check nightly package where dates are known
    if channel == "nightly":
        check_nightly_binaries_date(package)
    else:
        if not torch.__version__.startswith(stable_version):
            raise RuntimeError(
                f"Torch version mismatch, expected {stable_version} for channel {channel}. But its {torch.__version__}"
            )

def check_nightly_binaries_date(package: str) -> None:
    from datetime import datetime, timedelta
    format_dt = '%Y%m%d'

    torch_str = torch.__version__
    date_t_str = re.findall("dev\d+", torch.__version__)
    date_t_delta = datetime.now() - datetime.strptime(date_t_str[0][3:], format_dt)
    if date_t_delta.days >= NIGHTLY_ALLOWED_DELTA:
        raise RuntimeError(
            f"the binaries are from {date_t_str} and are more than {NIGHTLY_ALLOWED_DELTA} days old!"
        )

    if(package == "all"):
        for module in MODULES:
            imported_module = importlib.import_module(module["name"])
            module_version = imported_module.__version__
            date_m_str = re.findall("dev\d+", module_version)
            date_m_delta = datetime.now() - datetime.strptime(date_m_str[0][3:], format_dt)
            print(f"Nightly date check for {module['name']} version {module_version}")
            if date_m_delta.days > NIGHTLY_ALLOWED_DELTA:
                raise RuntimeError(
                    f"Expected {module['name']} to be less then {NIGHTLY_ALLOWED_DELTA} days. But its {date_m_delta}"
                )

def test_cuda_runtime_errors_captured() -> None:
    cuda_exception_missed=True
    try:
        print("Testing test_cuda_runtime_errors_captured")
        torch._assert_async(torch.tensor(0, device="cuda"))
        torch._assert_async(torch.tensor(0 + 0j, device="cuda"))
    except RuntimeError as e:
        if re.search("CUDA", f"{e}"):
            print(f"Caught CUDA exception with success: {e}")
            cuda_exception_missed = False
        else:
            raise e
    if(cuda_exception_missed):
        raise RuntimeError( f"Expected CUDA RuntimeError but have not received!")

def smoke_test_cuda(package: str) -> None:
    if not torch.cuda.is_available() and is_cuda_system:
        raise RuntimeError(f"Expected CUDA {gpu_arch_ver}. However CUDA is not loaded.")

    if(package == 'all' and is_cuda_system):
        for module in MODULES:
            imported_module = importlib.import_module(module["name"])
            # TBD for vision move extension module to private so it will
            # be _extention.
            version = "N/A"
            if module["extension"] == "extension":
                version = imported_module.extension._check_cuda_version()
            else:
                version = imported_module._extension._check_cuda_version()
            print(f"{module['name']} CUDA: {version}")

    if torch.cuda.is_available():
        if torch.version.cuda != gpu_arch_ver:
            raise RuntimeError(
                f"Wrong CUDA version. Loaded: {torch.version.cuda} Expected: {gpu_arch_ver}"
            )
        print(f"torch cuda: {torch.version.cuda}")
        # todo add cudnn version validation
        print(f"torch cudnn: {torch.backends.cudnn.version()}")
        print(f"cuDNN enabled? {torch.backends.cudnn.enabled}")

        # torch.compile is available only on Linux and python 3.8-3.10
        if (sys.platform == "linux" or sys.platform == "linux2") and sys.version_info < (3, 11, 0):
            smoke_test_compile()

        test_cuda_runtime_errors_captured()


def smoke_test_conv2d() -> None:
    import torch.nn as nn

    print("Testing smoke_test_conv2d")
    # With square kernels and equal stride
    m = nn.Conv2d(16, 33, 3, stride=2)
    # non-square kernels and unequal stride and with padding
    m = nn.Conv2d(16, 33, (3, 5), stride=(2, 1), padding=(4, 2))
    # non-square kernels and unequal stride and with padding and dilation
    basic_conv = nn.Conv2d(16, 33, (3, 5), stride=(2, 1), padding=(4, 2), dilation=(3, 1))
    input = torch.randn(20, 16, 50, 100)
    output = basic_conv(input)

    if is_cuda_system:
        print("Testing smoke_test_conv2d with cuda")
        conv = nn.Conv2d(3, 3, 3).cuda()
        x = torch.randn(1, 3, 24, 24).cuda()
        with torch.cuda.amp.autocast():
            out = conv(x)

        supported_dtypes = [torch.float16, torch.float32, torch.float64]
        for dtype in supported_dtypes:
            print(f"Testing smoke_test_conv2d with cuda for {dtype}")
            conv = basic_conv.to(dtype).cuda()
            input = torch.randn(20, 16, 50, 100, device="cuda").type(dtype)
            output = conv(input)

def smoke_test_linalg() -> None:
    print("Testing smoke_test_linalg")
    A = torch.randn(5, 3)
    U, S, Vh = torch.linalg.svd(A, full_matrices=False)
    U.shape, S.shape, Vh.shape
    torch.dist(A, U @ torch.diag(S) @ Vh)

    U, S, Vh = torch.linalg.svd(A)
    U.shape, S.shape, Vh.shape
    torch.dist(A, U[:, :3] @ torch.diag(S) @ Vh)

    A = torch.randn(7, 5, 3)
    U, S, Vh = torch.linalg.svd(A, full_matrices=False)
    torch.dist(A, U @ torch.diag_embed(S) @ Vh)

    if is_cuda_system:
        supported_dtypes = [torch.float32, torch.float64]
        for dtype in supported_dtypes:
            print(f"Testing smoke_test_linalg with cuda for {dtype}")
            A = torch.randn(20, 16, 50, 100, device="cuda").type(dtype)
            torch.linalg.svd(A)

def smoke_test_compile() -> None:
    supported_dtypes = [torch.float16, torch.float32, torch.float64]
    def foo(x: torch.Tensor) -> torch.Tensor:
        return torch.sin(x) + torch.cos(x)
    for dtype in supported_dtypes:
        print(f"Testing smoke_test_compile for {dtype}")
        x = torch.rand(3, 3, device="cuda").type(dtype)
        x_eager = foo(x)
        x_pt2 = torch.compile(foo)(x)
        print(torch.allclose(x_eager, x_pt2))


def smoke_test_modules():
    for module in MODULES:
        if module["repo"]:
            subprocess.check_output(f"git clone --depth 1 {module['repo']}", stderr=subprocess.STDOUT, shell=True)
            try:
                output = subprocess.check_output(
                    module["smoke_test"], stderr=subprocess.STDOUT, shell=True,
                    universal_newlines=True)
            except subprocess.CalledProcessError as exc:
                raise RuntimeError(
                        f"Module {module['name']} FAIL: {exc.returncode} Output: {exc.output}"
                    )
            else:
                print("Output: \n{}\n".format(output))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--package",
        help="Package to include in smoke testing",
        type=str,
        choices=["all", "torchonly"],
        default="all",
    )
    options = parser.parse_args()
    print(f"torch: {torch.__version__}")
    check_version(options.package)
    smoke_test_conv2d()
    smoke_test_linalg()

    if options.package == "all":
        smoke_test_modules()

    smoke_test_cuda(options.package)


if __name__ == "__main__":
    main()
