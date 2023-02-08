SHELL=/usr/bin/env bash

DESIRED_CUDA ?= 11.6
PACKAGE_NAME ?= magma-cuda116
CUDA_ARCH_LIST ?= -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86

DOCKER_RUN = set -eou pipefail; docker run --rm -i \
	-v $(shell git rev-parse --show-toplevel):/builder \
	-w /builder \
	-e DESIRED_CUDA=${DESIRED_CUDA} \
	-e PACKAGE_NAME=${PACKAGE_NAME} \
	-e CUDA_ARCH_LIST="${CUDA_ARCH_LIST}" \
	"pytorch/conda-builder:cuda${DESIRED_CUDA}" \
	magma/build_magma.sh

.PHONY: all
all: magma-cuda118
all: magma-cuda117
all: magma-cuda116

.PHONY:
clean:
	$(RM) -r magma-*
	$(RM) -r output

.PHONY: magma-cuda120
magma-cuda120: DESIRED_CUDA := 12.0
magma-cuda120: PACKAGE_NAME := magma-cuda120
magma-cuda120: CUDA_ARCH_LIST += -gencode arch=compute_90,code=sm_90
magma-cuda120:
	$(DOCKER_RUN)

.PHONY: magma-cuda118
magma-cuda118: DESIRED_CUDA := 11.8
magma-cuda118: PACKAGE_NAME := magma-cuda118
magma-cuda118: CUDA_ARCH_LIST += -gencode arch=compute_90,code=sm_90
magma-cuda118:
	$(DOCKER_RUN)

.PHONY: magma-cuda117
magma-cuda117: DESIRED_CUDA := 11.7
magma-cuda117: PACKAGE_NAME := magma-cuda117
magma-cuda117:
	$(DOCKER_RUN)

.PHONY: magma-cuda116
magma-cuda116: DESIRED_CUDA := 11.6
magma-cuda116: PACKAGE_NAME := magma-cuda116
magma-cuda116:
	$(DOCKER_RUN)
