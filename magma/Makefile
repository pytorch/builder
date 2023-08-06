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
all: magma-cuda121
all: magma-cuda118

.PHONY:
clean:
	$(RM) -r magma-*
	$(RM) -r output

.PHONY: magma-cuda121
magma-cuda121: DESIRED_CUDA := 12.1
magma-cuda121: PACKAGE_NAME := magma-cuda121
magma-cuda121:
	$(DOCKER_RUN)

.PHONY: magma-cuda118
magma-cuda118: DESIRED_CUDA := 11.8
magma-cuda118: PACKAGE_NAME := magma-cuda118
magma-cuda118: CUDA_ARCH_LIST += -gencode arch=compute_37,code=sm_37
magma-cuda118:
	$(DOCKER_RUN)

