#!/usr/bin/env bash

# Make sure to update these versions when doing a release first
PYTORCH_VERSION=${PYTORCH_VERSION:-2.2.0}
TORCHVISION_VERSION=${TORCHVISION_VERSION:-0.17.0}
TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION:-2.2.0}
TORCHTEXT_VERSION=${TORCHTEXT_VERSION:-0.17.0}
TORCHDATA_VERSION=${TORCHDATA_VERSION:-0.7.1}
TORCHREC_VERSION=${TORCHREC_VERSION:-0.6.0}

# NB: FBGEMMGPU uses the practice of keeping rc version in the filename, i.e.
# fbgemm_gpu-0.6.0rc1+cpu-cp311-cp311. On the other hand, its final RC will
# be without rc suffix, fbgemm_gpu-0.6.0+cpu-cp311-cp311, and that's the one
# ready to be promoted. So, keeping a + here in the version name allows the
# promote script to find the correct binaries
FBGEMMGPU_VERSION=${FBGEMMGPU_VERSION:-0.6.0+}
