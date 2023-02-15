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
# use installation env variable to tell if it is nightly channel
installation_str = os.getenv("MATRIX_INSTALLATION")
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

def cuda_runtime_error():
    cuda_exception_missed=True
    try:
        torch._assert_async(torch.tensor(0, device="cuda"))
        torch._assert_async(torch.tensor(0 + 0j, device="cuda"))
    except RuntimeError as e:
        if re.search("CUDA", f"{e}"):
            print(f"Caught CUDA exception with success: {e}")
            cuda_exception_missed = False
        else:
            raise(e)
    if(cuda_exception_missed):
        raise RuntimeError( f"Expected CUDA RuntimeError but have not received!")

def smoke_test_cuda(package: str) -> None:
    if not torch.cuda.is_available() and is_cuda_system:
        raise RuntimeError(f"Expected CUDA {gpu_arch_ver}. However CUDA is not loaded.")
    if torch.cuda.is_available():
        if torch.version.cuda != gpu_arch_ver:
            raise RuntimeError(
                f"Wrong CUDA version. Loaded: {torch.version.cuda} Expected: {gpu_arch_ver}"
            )
        print(f"torch cuda: {torch.version.cuda}")
        # todo add cudnn version validation
        print(f"torch cudnn: {torch.backends.cudnn.version()}")
        print(f"cuDNN enabled? {torch.backends.cudnn.enabled}")

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


def smoke_test_conv2d() -> None:
    import torch.nn as nn

    print("Calling smoke_test_conv2d")
    # With square kernels and equal stride
    m = nn.Conv2d(16, 33, 3, stride=2)
    # non-square kernels and unequal stride and with padding
    m = nn.Conv2d(16, 33, (3, 5), stride=(2, 1), padding=(4, 2))
    # non-square kernels and unequal stride and with padding and dilation
    m = nn.Conv2d(16, 33, (3, 5), stride=(2, 1), padding=(4, 2), dilation=(3, 1))
    input = torch.randn(20, 16, 50, 100)
    output = m(input)
    if is_cuda_system:
        print("Testing smoke_test_conv2d with cuda")
        conv = nn.Conv2d(3, 3, 3).cuda()
        x = torch.randn(1, 3, 24, 24).cuda()
        with torch.cuda.amp.autocast():
            out = conv(x)

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
    smoke_test_cuda(options.package)
    smoke_test_conv2d()

    if options.package == "all":
        smoke_test_modules()

    # only makes sense to check nightly package where dates are known
    if installation_str.find("nightly") != -1:
        check_nightly_binaries_date(options.package)

    # This check has to be run last, since its messing up CUDA runtime
    if torch.cuda.is_available():
        cuda_runtime_error()


if __name__ == "__main__":
    main()
