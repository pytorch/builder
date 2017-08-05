- bump version in setup.py
- cut branch
- upload generated docs and add to version selector


# new wheels

Run this command:

```
nvidia-docker run -it --rm -v $(pwd):/remote soumith/manylinux-cuda:latest bash
# OR
nvidia-docker run -it --rm -v $(pwd):/remote soumith/manylinux-cuda75:latest bash
```

Then run:

```
./remote/build.sh
```

Once done, upload wheels via:

```
./upload.sh
```







# Docker image

First run

```
./deploy.sh
```

Then run

```
docker push soumith/manylinux-cuda
```




# old instructions
Run this command:

```
nvidia-docker run -it --rm -v $(pwd):/remote nvidia/cuda:8.0-devel-centos6 bash
```

In docker image

```
./remote/conda_build.sh

cd /b
. /py/bin/activate
. /remote/atoken
cd /b/wheel/
./build_all.sh
```
