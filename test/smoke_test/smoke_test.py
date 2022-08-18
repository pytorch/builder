import torch
import torchvision
import torchaudio
import torch.nn as nn
import torchaudio.compliance.kaldi  # noqa: F401
import torchaudio.datasets  # noqa: F401
import torchaudio.functional  # noqa: F401
import torchaudio.models  # noqa: F401
import torchaudio.pipelines  # noqa: F401
import torchaudio.sox_effects  # noqa: F401
import torchaudio.transforms  # noqa: F401
import torchaudio.utils  # noqa: F401
from torchaudio.io import StreamReader
import torchvision.datasets as dset
import torchvision.transforms
print(torch.__version__)
print(torchvision.__version__)
print(torchaudio.__version__)
print('Is torchvision useable?', all(x is not None for x in [torch.ops.image.decode_png, torch.ops.torchvision.roi_align]))
print(f"CUDA IS AVAILABLE: {torch.cuda.is_available()}")
if() {

}
