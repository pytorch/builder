import os
import sys
import torch
import torchvision
import torchaudio

def smoke_test_cuda() -> None:
    gpu_arch_ver = os.getenv('GPU_ARCH_VER')
    gpu_arch_type = os.getenv('GPU_ARCH_TYPE')
    is_cuda_system = gpu_arch_type == "cuda"

    if(not torch.cuda.is_available() and is_cuda_system):
        print(f"Expected CUDA {gpu_arch_ver}. However CUDA is not loaded.")
        sys.exit(1)
    if(torch.cuda.is_available()):
        if(torch.version.cuda != gpu_arch_ver):
            print(f"Wrong CUDA version. Loaded: {torch.version.cuda} Expected: {gpu_arch_ver}")
            sys.exit(1)
        y=torch.randn([3,5]).cuda()
        print(f"torch cuda: {torch.version.cuda}")
        printf(f"torchvision cuda: {torch.ops.torchvision._cuda_version()}")
        #todo add cudnn version validation
        print(f"torch cudnn: {torch.backends.cudnn.version()}")

def smoke_test_torchvision() -> None:
    import torchvision.datasets as dset
    import torchvision.transforms
    print('Is torchvision useable?', all(x is not None for x in [torch.ops.image.decode_png, torch.ops.torchvision.roi_align]))

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
    #todo add torch, torchvision and torchaudio tests
    print(f"torch: {torch.__version__}")
    print(f"torchvision: {torchvision.__version__}")
    print(f"torchaudio: {torchaudio.__version__}")
    smoke_test_cuda()
    smoke_test_torchvision()
    smoke_test_torchaudio()

if __name__ == "__main__":
    main()
