SHELL=/usr/bin/env bash

DESIRED_CUDA ?= 11.3
PACKAGE_NAME ?= magma-cuda113
CUDA_ARCH_LIST ?= -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70

DOCKER_RUN = set -eou pipefail; docker run --rm -i \
	-v $(shell git rev-parse --show-toplevel):/builder \
	-w /builder \
	-e DESIRED_CUDA=${DESIRED_CUDA} \
	-e PACKAGE_NAME=${PACKAGE_NAME} \
	-e CUDA_ARCH_LIST="${CUDA_ARCH_LIST}" \
	"pytorch/conda-builder:cuda${DESIRED_CUDA}" \
	magma/build_magma.sh

.PHONY: all
all: magma-cuda116
all: magma-cuda115
all: magma-cuda113
all: magma-cuda102

.PHONY:
clean:
	$(RM) -r magma-*
	$(RM) -r output

.PHONY: magma-cuda116
magma-cuda116: DESIRED_CUDA := 11.6
magma-cuda116: PACKAGE_NAME := magma-cuda116
magma-cuda116: CUDA_ARCH_LIST += -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86
magma-cuda116:
	$(DOCKER_RUN)

.PHONY: magma-cuda115
magma-cuda115: DESIRED_CUDA := 11.5
magma-cuda115: PACKAGE_NAME := magma-cuda115
magma-cuda115: CUDA_ARCH_LIST += -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86
magma-cuda115:
	$(DOCKER_RUN)

.PHONY: magma-cuda113
magma-cuda113: DESIRED_CUDA := 11.3
magma-cuda113: PACKAGE_NAME := magma-cuda113
magma-cuda113: CUDA_ARCH_LIST += -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86
magma-cuda113:
	$(DOCKER_RUN)

.PHONY: magma-cuda102
magma-cuda102: DESIRED_CUDA := 10.2
magma-cuda102: PACKAGE_NAME := magma-cuda102
magma-cuda102:
	$(DOCKER_RUN)
