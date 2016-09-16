#!/usr/bin/env bash

echo "here in build_nimbix"

set -e

PROJECT=$1
GIT_COMMIT=$2
GIT_BRANCH=$3
GITHUB_TOKEN=$4
PYTHON_VERSION=$5

if [ "$#" -ne 5 ]
then
  echo "Did not find 5 arguments" >&2
  exit 1
fi

echo "Username: $USER"
echo "Homedir: $HOME"
echo "Home ls:"
ls -alh ~/
echo "Home permissions:"
ls -alh ~/../
echo "Current directory: $(pwd)"
echo "Project: $PROJECT"
echo "Branch: $GIT_BRANCH"
echo "Commit: $GIT_COMMIT"

echo "Installing dependencies"

echo "Disks:"
df -h

echo "running nvidia-smi"

nvidia-smi

export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

if ! which nvcc
then
    echo "Downloading CUDA 7.5"
    wget -c http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run -O ~/cuda_7.5.18_linux.run

    echo "Installing CUDA 7.5"
    chmod +x ~/cuda_7.5.18_linux.run
    sudo bash ~/cuda_7.5.18_linux.run --silent --toolkit --no-opengl-libs

    echo "\nDone installing CUDA 7.5"
else
    echo "CUDA 7.5 already installed"
fi

echo "nvcc: $(which nvcc)"

echo "Checking Miniconda"

if ! ls ~/miniconda
then
    echo "Miniconda needs to be installed"
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
    bash ~/miniconda.sh -b -p $HOME/miniconda
else
    echo "Miniconda is already installed"
fi

export PATH="$HOME/miniconda/bin:$PATH"

# by default we install py3. If requested py2, create env and activate
if [ $PYTHON_VERSION -eq 2 ]
then
    echo "Requested python version 2. Activating conda environment"
    if ! conda info --envs | grep py2k
    then
	# create virtual env and activate it
	conda create -n py2k python=2 -y
    fi
    source activate py2k
fi

if ! which cmake
then
    conda install -y cmake
fi

echo "Python Version:"
python --version

echo "Installing $PROJECT at branch $GIT_BRANCH and commit $GIT_COMMIT"
rm -rf $PROJECT
git clone https://pytorchbot:$GITHUB_TOKEN@github.com/pytorch/$PROJECT --quiet 
cd $PROJECT
git -c core.askpass=true fetch --tags https://pytorchbot:$GITHUB_TOKEN@github.com/pytorch/$PROJECT +refs/pull/*:refs/remotes/origin/pr/* --quiet
git checkout $GIT_BRANCH
pip install -r requirements.txt || true
time python setup.py install

echo "Testing pytorch"
time python test/test_torch.py
time python test/test_legacy_nn.py
time python test/test_nn.py
time python test/test_autograd.py
time python test/test_cuda.py

echo "ALL CHECKS PASSED"

# this is needed, i think because of a bug in nimbix-wrapper.py
# otherwise, ALL CHECKS PASSED is not getting printed out sometimes
sleep 10
