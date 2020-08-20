# llvm

This contains the dockerfile used to build LLVM from source with assertions enabled.

This is ultimately used by the main `pytorch/pytorch`'s base Docker images

## How to build:

```bash
./build.sh
```

## How to deploy:

```
./deploy.sh
```

## Updating LLVM

Edit the LLVM_VERSION in `env_vars.sh`
