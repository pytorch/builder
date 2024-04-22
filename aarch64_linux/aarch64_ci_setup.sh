#!/bin/bash
set -eux -o pipefail

# This script is used to prepare the Docker container for aarch64_ci_wheel_build.py python script
# as we need to setup the required python version and install few tools.
if [ "$DESIRED_PYTHON" == "3.8" ] || [ "$DESIRED_PYTHON" == "3.9" ] || [ "$DESIRED_PYTHON" == "3.11" ]; then
    dnf install -y python$DESIRED_PYTHON

elif [ "$DESIRED_PYTHON" == "3.10" ] || [ "$DESIRED_PYTHON" == "3.12" ]; then
   if [ "$DESIRED_PYTHON" == "3.10" ]; then
      PYTHON_INSTALLED_VERSION="3.10.14"
   else
      PYTHON_INSTALLED_VERSION="3.12.3"
   fi
   wget https://www.python.org/ftp/python/${PYTHON_INSTALLED_VERSION}/Python-${PYTHON_INSTALLED_VERSION}.tgz
   tar xzf Python-${PYTHON_INSTALLED_VERSION}.tgz
   cd Python-${PYTHON_INSTALLED_VERSION}
   ./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
   make -j 8
   make altinstall
   cd ..
   rm Python-${PYTHON_INSTALLED_VERSION}.tgz
else
   echo "unsupported python version passed. 3.8, 3.9, 3.10 or 3.11 are the only supported versions"
   exit 1
fi

/usr/local/bin/python${DESIRED_PYTHON} -m venv appenv${DESIRED_PYTHON}
source appenv${DESIRED_PYTHON}/bin/activate
python3 --version

python3 -m pip install dataclasses typing-extensions scons pyyaml pygit2 ninja patchelf Cython
if [[ "$DESIRED_PYTHON"  == "3.8" ]]; then
    python3 -m pip install -q numpy==1.24.4
else
    python3 -m pip install -q --pre numpy==2.0.0rc1
fi
