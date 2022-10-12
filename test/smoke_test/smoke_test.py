import os
import re
import sys
from pathlib import Path

import torch
import torchaudio

# the following import would invoke
# _check_cuda_version()
# via torchvision.extension._check_cuda_version()
import torchvision

gpu_arch_ver = os.getenv("GPU_ARCH_VER")
gpu_arch_type = os.getenv("GPU_ARCH_TYPE")
# use installation env variable to tell if it is nightly channel
installation_str = os.getenv("INSTALLATION")
is_cuda_system = gpu_arch_type == "cuda"
SCRIPT_DIR = Path(__file__).parent

# helper function to return the conda installed packages
# and return  package we are insterseted in
def get_anaconda_output_for_package(pkg_name_str):
    import subprocess as sp

    cmd = "conda list --explicit"
    output = sp.getoutput(cmd)
    for item in output.split("\n"):
        if pkg_name_str in item:
            return item

    # Get the last line only
    return f"{pkg_name_str} can't be found"


def check_nightly_binaries_date() -> None:
    torch_str = torch.__version__
    ta_str = torchaudio.__version__
    tv_str = torchvision.__version__

    date_t_str = re.findall("dev\d+", torch.__version__)
    date_ta_str = re.findall("dev\d+", torchaudio.__version__)
    date_tv_str = re.findall("dev\d+", torchvision.__version__)

    # check that the above three lists are equal and none of them is empty
    if not date_t_str or not date_t_str == date_ta_str == date_tv_str:
        raise RuntimeError(
            f"Expected torch, torchaudio, torchvision to be the same date. But they are from {date_t_str}, {date_ta_str}, {date_tv_str} respectively"
        )

    # check that the date is recent, at this point, date_torch_str is not empty
    binary_date_str = date_t_str[0][3:]
    from datetime import datetime

    binary_date_obj = datetime.strptime(binary_date_str, "%Y%m%d").date()
    today_obj = datetime.today().date()
    delta = today_obj - binary_date_obj
    if delta.days >= 2:
        raise RuntimeError(
            f"the binaries are from {binary_date_obj} and are more than 2 days old!"
        )


def smoke_test_cuda() -> None:
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


def smoke_test_torchvision_resnet50_classify() -> None:
    from torchvision.io import read_image
    from torchvision.models import resnet50, ResNet50_Weights

    img = read_image(str(SCRIPT_DIR / "assets" / "dog2.jpg"))

    # Step 1: Initialize model with the best available weights
    weights = ResNet50_Weights.DEFAULT
    model = resnet50(weights=weights)
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
    import torchaudio.compliance.kaldi  # noqa: F401
    import torchaudio.datasets  # noqa: F401
    import torchaudio.functional  # noqa: F401
    import torchaudio.models  # noqa: F401
    import torchaudio.pipelines  # noqa: F401
    import torchaudio.sox_effects  # noqa: F401
    import torchaudio.transforms  # noqa: F401
    import torchaudio.utils  # noqa: F401


def main() -> None:
    # todo add torch, torchvision and torchaudio tests
    print(f"torch: {torch.__version__}")
    print(f"torchvision: {torchvision.__version__}")
    print(f"torchaudio: {torchaudio.__version__}")
    smoke_test_cuda()

    # only makes sense to check nightly package where dates are known
    if installation_str.find("nightly") != -1:
        check_nightly_binaries_date()

    smoke_test_conv2d()
    smoke_test_torchaudio()
    smoke_test_torchvision()
    smoke_test_torchvision_read_decode()
    smoke_test_torchvision_resnet50_classify()


if __name__ == "__main__":
    main()
