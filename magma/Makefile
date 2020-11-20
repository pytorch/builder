SHELL=/usr/bin/env bash

DESIRED_CUDA ?= 11.1

DOCKER_RUN = set -eou pipefail; docker run --rm -i \
    -v $(shell git rev-parse --show-toplevel):/builder \
    -w /builder \
    -e "DESIRED_CUDA=${DESIRED_CUDA}" \
    "pytorch/conda-cuda:latest" \
    magma/build_magma.sh

.PHONY: magma-cuda111
magma-cuda111: DESIRED_CUDA := 11.1
magma-cuda111:
	$(DOCKER_RUN)

.PHONY: magma-cuda110
magma-cuda110: DESIRED_CUDA := 11.0
magma-cuda110:
	$(DOCKER_RUN)

.PHONY: magma-cuda102
magma-cuda102: DESIRED_CUDA := 10.2
magma-cuda102:
	$(DOCKER_RUN)

.PHONY: magma-cuda101
magma-cuda101: DESIRED_CUDA := 10.1
magma-cuda101:
	$(DOCKER_RUN)

.PHONY: magma-cuda92
magma-cuda92: DESIRED_CUDA := 9.2
magma-cuda92:
	$(DOCKER_RUN)
