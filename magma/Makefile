SHELL=/usr/bin/env bash

DESIRED_CUDA ?= 11.8
PACKAGE_NAME ?= magma-cuda118
CUDA_ARCH_LIST ?= -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86 -gencode arch=compute_90,code=sm_90

DOCKER_RUN = set -eou pipefail; docker run --rm -i \
	-v $(shell git rev-parse --show-toplevel):/builder \
	-w /builder \
	-e DESIRED_CUDA=${DESIRED_CUDA} \
	-e PACKAGE_NAME=${PACKAGE_NAME} \
	-e CUDA_ARCH_LIST="${CUDA_ARCH_LIST}" \
	"pytorch/conda-builder:cuda${DESIRED_CUDA}" \
	magma/build_magma.sh

.PHONY: all
all: magma-cuda128

.PHONY:
clean:
	$(RM) -r magma-*
	$(RM) -r output

.PHONY: magma-cuda128
magma-cuda126: DESIRED_CUDA := 12.8
magma-cuda126: PACKAGE_NAME := magma-cuda128
magma-cuda126:
	$(DOCKER_RUN)

