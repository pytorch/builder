import os
import re
import sys
from pathlib import Path
import argparse
import torch

gpu_arch_ver = os.getenv("GPU_ARCH_VER")
gpu_arch_type = os.getenv("GPU_ARCH_TYPE")
# use installation env variable to tell if it is nightly channel
installation_str = os.getenv("INSTALLATION")
is_cuda_system = gpu_arch_type == "cuda"
SCRIPT_DIR = Path(__file__).parent
NIGHTLY_ALLOWED_DELTA = 3

# helper function to return the conda installed packages
# and return  package we are insterseted in
def get_anaconda_output_for_package(pkg_name_str):
    import subprocess as sp

    # If we are installing using conda just list package name
    if installation_str.find("conda install") != -1:
        cmd = "conda list --explicit"
        output = sp.getoutput(cmd)
        for item in output.split("\n"):
            if pkg_name_str in item:
                return item
        return f"{pkg_name_str} can't be found"
    else:
        cmd = "conda list -f " + pkg_name_str
        output = sp.getoutput(cmd)
        # Get the last line only
        return output.strip().split('\n')[-1]


def check_nightly_binaries_date(package: str) -> None:
    from datetime import datetime, timedelta
    format_dt = '%Y%m%d'

    torch_str = torch.__version__
    date_t_str = re.findall("dev\d+", torch.__version__)
    date_t_delta = datetime.now() - datetime.strptime(date_t_str.lstrip("dev"), format_dt)
    if date_t_delta.days >= NIGHTLY_ALLOWED_DELTA:
        raise RuntimeError(
            f"the binaries are from {date_t_str} and are more than {NIGHTLY_ALLOWED_DELTA} days old!"
        )

    if(package == "all"):
        ta_str = torchaudio.__version__
        tv_str = torchvision.__version__
        date_ta_str = re.findall("dev\d+", torchaudio.__version__)
        date_tv_str = re.findall("dev\d+", torchvision.__version__)
        date_ta_delta = datetime.now() - datetime.strptime(date_ta_str.lstrip("dev"), format_dt)
        date_tv_delta = datetime.now() - datetime.strptime(date_tv_str.lstrip("dev"), format_dt)

        # check that the above three lists are equal and none of them is empty
        if date_ta_delta.days > NIGHTLY_ALLOWED_DELTA or date_tv_delta.days > NIGHTLY_ALLOWED_DELTA:
            raise RuntimeError(
                f"Expected torchaudio, torchvision to be less then {NIGHTLY_ALLOWED_DELTA} days. But they are from {date_ta_str}, {date_tv_str} respectively"
            )


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

    if(package == 'all'):
        import torchaudio
        import torchvision
        if installation_str.find("nightly") != -1:
            # just print out cuda version, as version check were already performed during import
            print(f"torchvision cuda: {torch.ops.torchvision._cuda_version()}")
            print(f"torchaudio cuda: {torch.ops.torchaudio.cuda_version()}")
        else:
            # torchaudio runtime added the cuda verison check on 09/23/2022 via
            # https://github.com/pytorch/audio/pull/2707
            # so relying on anaconda output for pytorch-test and pytorch channel
            torchaudio_allstr = get_anaconda_output_for_package(torchaudio.__name__)
            if (
                is_cuda_system
                and "cu" + str(gpu_arch_ver).replace(".", "") not in torchaudio_allstr
            ):
                raise RuntimeError(
                    f"CUDA version issue. Loaded: {torchaudio_allstr} Expected: {gpu_arch_ver}"
                )

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


def smoke_test_torchvision() -> None:
    print(
        "Is torchvision useable?",
        all(
            x is not None
            for x in [torch.ops.image.decode_png, torch.ops.torchvision.roi_align]
        ),
    )


def smoke_test_torchvision_read_decode() -> None:
    from torchvision.io import read_image

    img_jpg = read_image(str(SCRIPT_DIR / "assets" / "rgb_pytorch.jpg"))
    if img_jpg.ndim != 3 or img_jpg.numel() < 100:
        raise RuntimeError(f"Unexpected shape of img_jpg: {img_jpg.shape}")
    img_png = read_image(str(SCRIPT_DIR / "assets" / "rgb_pytorch.png"))
    if img_png.ndim != 3 or img_png.numel() < 100:
        raise RuntimeError(f"Unexpected shape of img_png: {img_png.shape}")


def smoke_test_torchvision_resnet50_classify(device: str = "cpu") -> None:
    from torchvision.io import read_image
    from torchvision.models import resnet50, ResNet50_Weights

    img = read_image(str(SCRIPT_DIR / "assets" / "dog2.jpg")).to(device)

    # Step 1: Initialize model with the best available weights
    weights = ResNet50_Weights.DEFAULT
    model = resnet50(weights=weights).to(device)
    model.eval()

    # Step 2: Initialize the inference transforms
    preprocess = weights.transforms()

    # Step 3: Apply inference preprocessing transforms
    batch = preprocess(img).unsqueeze(0)

    # Step 4: Use the model and print the predicted category
    prediction = model(batch).squeeze(0).softmax(0)
    class_id = prediction.argmax().item()
    score = prediction[class_id].item()
    category_name = weights.meta["categories"][class_id]
    expected_category = "German shepherd"
    print(f"{category_name}: {100 * score:.1f}%")
    if category_name != expected_category:
        raise RuntimeError(
            f"Failed ResNet50 classify {category_name} Expected: {expected_category}"
        )


def smoke_test_torchaudio() -> None:
    import torchaudio
    import torchaudio.compliance.kaldi  # noqa: F401
    import torchaudio.datasets  # noqa: F401
    import torchaudio.functional  # noqa: F401
    import torchaudio.models  # noqa: F401
    import torchaudio.pipelines  # noqa: F401
    import torchaudio.sox_effects  # noqa: F401
    import torchaudio.transforms  # noqa: F401
    import torchaudio.utils  # noqa: F401


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

    # only makes sense to check nightly package where dates are known
    if installation_str.find("nightly") != -1:
        check_nightly_binaries_date(options.package)

    if options.package == "all":
        import torchaudio
        import torchvision
        print(f"torchvision: {torchvision.__version__}")
        print(f"torchaudio: {torchaudio.__version__}")
        smoke_test_torchaudio()
        smoke_test_torchvision()
        smoke_test_torchvision_read_decode()
        smoke_test_torchvision_resnet50_classify()
        if torch.cuda.is_available():
            smoke_test_torchvision_resnet50_classify("cuda")

if __name__ == "__main__":
    main()
