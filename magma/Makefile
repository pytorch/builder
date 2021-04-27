SHELL=/usr/bin/env bash

DESIRED_CUDA ?= 11.1
PACKAGE_NAME ?= magma-cuda111
CUDA_POINTER_ATTR_PATCH ?=
CUDA_ARCH_LIST ?= -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70

DOCKER_RUN = set -eou pipefail; docker run --rm -i \
	-v $(shell git rev-parse --show-toplevel):/builder \
	-w /builder \
	-e DESIRED_CUDA=${DESIRED_CUDA} \
	-e PACKAGE_NAME=${PACKAGE_NAME} \
	-e CUDA_POINTER_ATTR_PATCH=${CUDA_POINTER_ATTR_PATCH} \
	-e CUDA_ARCH_LIST="${CUDA_ARCH_LIST}" \
	"pytorch/conda-builder:cuda${DESIRED_CUDA}" \
	magma/build_magma.sh

.PHONY: all
all: magma-cuda113
all: magma-cuda112
all: magma-cuda111
all: magma-cuda110
all: magma-cuda102
all: magma-cuda101
all: magma-cuda92

.PHONY:
clean:
	$(RM) -r magma-*
	$(RM) -r output

.PHONY: magma-cuda113
magma-cuda113: DESIRED_CUDA := 11.3
magma-cuda113: PACKAGE_NAME := magma-cuda113
magma-cuda113: CUDA_POINTER_ATTR_PATCH := "     - cudaPointerAttributes.patch"
magma-cuda113: CUDA_ARCH_LIST += -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86
magma-cuda113:
	$(DOCKER_RUN)

.PHONY: magma-cuda112
magma-cuda112: DESIRED_CUDA := 11.2
magma-cuda112: PACKAGE_NAME := magma-cuda112
magma-cuda112: CUDA_POINTER_ATTR_PATCH := "     - cudaPointerAttributes.patch"
magma-cuda112: CUDA_ARCH_LIST += -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86
magma-cuda112:
	$(DOCKER_RUN)

.PHONY: magma-cuda111
magma-cuda111: DESIRED_CUDA := 11.1
magma-cuda111: PACKAGE_NAME := magma-cuda111
magma-cuda111: CUDA_POINTER_ATTR_PATCH := "     - cudaPointerAttributes.patch"
magma-cuda111: CUDA_ARCH_LIST += -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86
magma-cuda111:
	$(DOCKER_RUN)

.PHONY: magma-cuda110
magma-cuda110: DESIRED_CUDA := 11.0
magma-cuda110: PACKAGE_NAME := magma-cuda110
magma-cuda110: CUDA_POINTER_ATTR_PATCH := "     - cudaPointerAttributes.patch"
magma-cuda110: CUDA_ARCH_LIST += -gencode arch=compute_80,code=sm_80
magma-cuda110:
	$(DOCKER_RUN)

.PHONY: magma-cuda102
magma-cuda102: DESIRED_CUDA := 10.2
magma-cuda102: PACKAGE_NAME := magma-cuda102
magma-cuda102:
	$(DOCKER_RUN)

.PHONY: magma-cuda101
magma-cuda101: DESIRED_CUDA := 10.1
magma-cuda101: PACKAGE_NAME := magma-cuda101
magma-cuda101:
	$(DOCKER_RUN)

.PHONY: magma-cuda92
magma-cuda92: DESIRED_CUDA := 9.2
magma-cuda92: PACKAGE_NAME := magma-cuda92
magma-cuda92:
	$(DOCKER_RUN)
