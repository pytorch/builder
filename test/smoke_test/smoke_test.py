import os
import sys
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
cuda_version_expected = os.environ['CUDA_VER']
is_cuda_system = cuda_version_expected != "cpu"
#todo add torch, torchvision and torchaudio tests
print(f"torch: {torch.__version__}")
print(f"torchvision: {torchvision.__version__}")
print(f"torchaudio: {torchaudio.__version__}")
print('Is torchvision useable?', all(x is not None for x in [torch.ops.image.decode_png, torch.ops.torchvision.roi_align]))
if(not torch.cuda.is_available() and is_cuda_system):
    print(f"Expected CUDA {cuda_version_expected}. However CUDA is not loaded.")
    sys.exit(1)
if(torch.cuda.is_available()):
    if(torch.version.cuda != cuda_version_expected):
        print(f"Wrong CUDA version. Loaded: {torch.version.cuda} Expected: {cuda_version_expected}")
        sys.exit(1)
    y=torch.randn([3,5]).cuda()
    print(torch.version.cuda)
    #todo add cudnn version validation
    print(torch.backends.cudnn.version())
