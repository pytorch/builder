# Magma

## Building

To build just run:

```
./build.sh
```

This should give you a docker image with `devtoolset3` installed in order to keep binary size down

To swap out CUDA versions to build just use the environment variable `DESIRED_CUDA`:

```
DESIRED_CUDA=10.2 ./build.sh
```

Outputted binaries should be in the `output` folder

## Pushing

Once you have built the binaries push them with:

```
anaconda upload -u pytorch --force output/*/magma-cuda*.bz2
```

If you do not have upload permissions, please ping @seemethere or @soumith to gain access
