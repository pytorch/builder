- bump version in setup.py
- cut branch
- upload generated docs and add to version selector


## Building new wheels

Run this command:

```
nvidia-docker run -it --ipc=host --rm -v $(pwd):/remote soumith/manylinux-cuda80:latest bash
# OR
nvidia-docker run -it --ipc=host --rm -v $(pwd):/remote soumith/manylinux-cuda90:latest bash
# OR
nvidia-docker run -it --ipc=host --rm -v $(pwd):/remote soumith/manylinux-cuda92:latest bash
```

Then run:

```
./remote/build.sh
```

Once done, upload wheels via:

```
./upload.sh
```

Upload the default cuda wheels to PyPI:

```
mkdir wheelhouse_manylinux
cp wheelhouse90/*.whl wheelhouse_manylinux/
ls -1 wheelhouse_manylinux/*.whl | awk '{print("mv "$1 " " $1)}' | sed 's/-linux_/-manylinux1_/2' | bash
twine upload wheelhouse_manylinux/*.whl
```

## Building Docker image

Run

```
./deploy.sh
```
