#!/bin/bash

set -eux -o pipefail

retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

BRANCH=""
if [[ ${MATRIX_CHANNEL} == "test" || ${MATRIX_CHANNEL} == "release" ]]; then
    SHORT_VERSION=${MATRIX_STABLE_VERSION%.*}
    BRANCH="--branch release/${SHORT_VERSION}"
fi


# Clone the Pytorch branch
retry git clone ${BRANCH} --depth 1 https://github.com/pytorch/pytorch.git
retry git submodule update --init --recursive
pushd pytorch

pip install expecttest numpy pyyaml jinja2 packaging hypothesis unittest-xml-reporting scipy

# Run pytorch cuda wheels validation
# Detect ReduceLogicKernel (ReduceOp and kernel) IMA
python test/test_ops.py -k test_dtypes_all_cuda
# Detect BinaryMulKernel (elementwise binary functor internal mul) IMA
python test/test_torch.py -k test_index_reduce_reduce_prod_cuda_int32
# Detect BinaryBitwiseOpsKernels (at::native::BitwiseAndFunctor) IMA
python test/test_binary_ufuncs.py -k test_contig_vs_every_other___rand___cuda_int32
# Detect MaxMinElementwiseKernel (maximum) IMA
python test/test_schema_check.py -k test_schema_correctness_clamp_cuda_int8

pushd /tmp
# Detect StepKernel (nextafter) IMA
python -c "import torch; print(torch.nextafter(torch.tensor([-4.5149, -5.9053, -0.9516, -2.3615,  1.5591], device='cuda:0'), torch.tensor(3.8075, device='cuda:0')))"
# Detect BinaryGeometricKernels (atan2) IMA
python -c "import torch; x = (torch.randn((2,1,1), dtype=torch.float, device='cuda')*5).to(torch.float32); y=(torch.randn((), dtype=torch.float, device='cuda')*5).to(torch.float32); print(torch.atan2(x,y))"
popd
