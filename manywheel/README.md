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

## Building Docker image

Run

```
./deploy.sh
```
