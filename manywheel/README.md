
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
```






























First run

```
./deploy.sh
```

Then run

```
docker push soumith/manylinux-cuda
```

