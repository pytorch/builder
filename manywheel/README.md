# pytorch/builder/manywheel

## Building docker images

To build all docker images you can use the convenience script:

```bash
# Build without pushing
manywheel/build_all_docker.sh
# Build with pushing
WITH_PUSH=1 manywheel/build_all_docker.sh
```

To build a specific docker image use:
```bash
# GPU_ARCH_TYPE can be ["cuda", "rocm", "cpu"]
# GPU_ARCH_VERSION is GPU_ARCH_TYPE dependent, see manywheel/build_all_docker.sh for examples
GPU_ARCH_TYPE=cuda GPU_ARCH_VERSION=11.1 manywheel/build_docker.sh
# Build with pushing
WITH_PUSH=1 GPU_ARCH_TYPE=cuda GPU_ARCH_VERSION=11.1 manywheel/build_docker.sh
```
