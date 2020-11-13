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

## New versions

New CUDA versions can be added by copying / pasting the latest magma folder to the next desired version and then
editing the `build.sh` and `meta.yml` files to reflect the new values

Example:
```bash
cp -r magma/magma-cuda110 magma/magma-cuda111
sed -i 's/11.0/11.1' magma/magma-cuda111/build.sh
sed -i 's/110/111/' magma/magma-cuda111/meta.yaml
```
