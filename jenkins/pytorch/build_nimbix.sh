#!/usr/bin/env bash

echo "here in build_nimbix"

set -e

PROJECT=$1
GIT_COMMIT=$2
GIT_BRANCH=$3
GITHUB_TOKEN=$4
PYTHON_VERSION=$5
OS=$6

if [ "$#" -ne 6 ]
then
  echo "Did not find 6 arguments" >&2
  exit 1
fi

echo "Username: $USER"
echo "Homedir: $HOME"
echo "Home ls:"
ls -alh ~/ || true
echo "Current directory: $(pwd)"
echo "Project: $PROJECT"
echo "Branch: $GIT_BRANCH"
echo "Commit: $GIT_COMMIT"
echo "OS: $OS"

echo "Installing dependencies"

echo "Disks:"
df -h || true

if [ "$OS" == "LINUX" ]; then
    echo "running nvidia-smi"
    nvidia-smi

    echo "Processor info"
    cat /proc/cpuinfo|grep "model name" | wc -l
    cat /proc/cpuinfo|grep "model name" | sort | uniq
    cat /proc/cpuinfo|grep "flags" | sort | uniq

    echo "Linux release:"
    lsb_release -a || true

else
    echo "Processor info"    
    sysctl -n machdep.cpu.brand_string
fi

uname -a


if [ "$OS" == "LINUX" ]; then
    # install and export ccache
    if ! ls ~/ccache/bin/ccache
    then
        sudo apt-get update
        sudo apt-get install -y automake autoconf
        sudo apt-get install -y asciidoc
        mkdir -p ~/ccache
        pushd /tmp
        rm -rf ccache
        git clone https://github.com/colesbury/ccache -b ccbin
        pushd ccache
        ./autogen.sh
        ./configure
        make install prefix=~/ccache
        popd
        popd

        mkdir -p ~/ccache/lib
        mkdir -p ~/ccache/cuda
        ln -s ~/ccache/bin/ccache ~/ccache/lib/cc
        ln -s ~/ccache/bin/ccache ~/ccache/lib/c++
        ln -s ~/ccache/bin/ccache ~/ccache/lib/gcc
        ln -s ~/ccache/bin/ccache ~/ccache/lib/g++
        ln -s ~/ccache/bin/ccache ~/ccache/cuda/nvcc

        ~/ccache/bin/ccache -M 25Gi
    fi

    export PATH=~/ccache/lib:$PATH
    export CUDA_NVCC_EXECUTABLE=~/ccache/cuda/nvcc

    # add cuda to PATH and LD_LIBRARY_PATH
    export PATH=/usr/local/cuda/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

    if ! ls /usr/local/cuda-8.0
    then
        echo "Downloading CUDA 8.0"
        wget -c https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda_8.0.44_linux-run -O ~/cuda_8.0.44_linux-run

        echo "Installing CUDA 8.0"
        chmod +x ~/cuda_8.0.44_linux-run
        sudo bash ~/cuda_8.0.44_linux-run --silent --toolkit --no-opengl-libs

        echo "\nDone installing CUDA 8.0"
    else
        echo "CUDA 8.0 already installed"
    fi

    echo "nvcc: $(which nvcc)"

    if ! ls /usr/local/cuda/lib64/libcudnn.so.6.0.21
    then
        echo "CuDNN 6.0.21 not found. Downloading and copying to /usr/local/cuda"
        mkdir -p /tmp/cudnn-download
        pushd /tmp/cudnn-download
        rm -rf cuda
        wget http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-8.0-linux-x64-v6.0.tgz
        tar -xvf cudnn-8.0-linux-x64-v6.0.tgz
        sudo cp -P cuda/include/* /usr/local/cuda/include/
        sudo cp -P cuda/lib64/* /usr/local/cuda/lib64/
        popd
        echo "Downloaded and installed CuDNN 6.0.21"
    fi

fi

echo "Checking Miniconda"


if [ "$OS" == "LINUX" ]; then
    miniconda_url="https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"
else
    miniconda_url="https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
fi

if ! ls ~/miniconda
then
    echo "Miniconda needs to be installed"
    # wget $miniconda_url -O ~/miniconda.sh
    curl $miniconda_url -o ~/miniconda.sh
    bash ~/miniconda.sh -b -p $HOME/miniconda
else
    echo "Miniconda is already installed"
fi

export PATH="$HOME/miniconda/bin:$PATH"


export CONDA_ROOT_PREFIX=$(conda info --root)

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
    export CONDA_ROOT_PREFIX="$HOME/miniconda/envs/py2k"
else
    source activate root
fi

echo "Conda root: $CONDA_ROOT_PREFIX"

if ! which cmake
then
    conda install -y cmake
fi

# install mkl
conda install -y mkl numpy

# install pyyaml (for setup)
conda install -y pyyaml

if [ "$OS" == "LINUX" ]; then
    conda install -y magma-cuda80 -c soumith
fi

# add mkl to CMAKE_PREFIX_PATH
export CMAKE_LIBRARY_PATH=$CONDA_ROOT_PREFIX/lib:$CONDA_ROOT_PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$CONDA_ROOT_PREFIX

echo "Python Version:"
python --version

# Why is this uninstall necessary?  In ordinary development,
# 'python setup.py install' will overwrite an old install, so
# it is not usually necessary uninstall the old install first.
# However, it turns out that setuptools performs this install
# simply by copying files one-by-one, overwriting the old files,
# NOT an uninstall and reinstall.  This means that there is one
# nasty edge case:  suppose you have an old install of
# 'foo/bar/__init__.py', and your new install is 'foo/bar.py'
# (although this is "rare" to occur in a project history, it
# might occur if you PR a change to use __init__, but then builder
# goes back and builds another PR without this change).
# Because there is no uninstall step, BOTH 'foo/bar.py' and
# 'foo/bar/__init__.py' will exist in the install, and
# 'foo/bar/__init__.py' will ALWAYS win import resolution, even
# though you wanted 'foo/bar.py'.
#
# The fix is simple: uninstall, then reinstall.  Of course, if the
# uninstall leaves files behind, you can still get into a bad situation,
# but it is less likely to occur now.
echo "Removing old builds of torch"
pip uninstall -y torch || true

echo "Installing $PROJECT at branch $GIT_BRANCH and commit $GIT_COMMIT"
rm -rf $PROJECT
git clone https://github.com/pytorch/$PROJECT --quiet
cd $PROJECT
git fetch --tags https://github.com/pytorch/$PROJECT +refs/pull/*:refs/remotes/origin/pr/* --quiet
git checkout $GIT_BRANCH
git submodule update --init --recursive

echo "Check if torch/lib/ATen was changed (temporary)"
git diff ${GIT_COMMIT}~:torch/lib/ATen ${GIT_COMMIT}:torch/lib/ATen --exit-code

if [ "$OS" == "OSX" ]; then
    export MACOSX_DEPLOYMENT_TARGET=10.9
    export CC=clang
    export CXX=clang++
fi
pip install -r requirements.txt || true
time python setup.py install

if [ ! -z "$jenkins_nightly" ]; then
    # Uninstall any leftover copies of onnx and onnx-caffe2
    echo "Removing any old builds"
    pip uninstall -y onnx || true
    pip uninstall -y onnx-caffe2 || true
    pip uninstall -y onnx-pytorch || true

    echo "Installing nightly dependencies"
    conda install -y -c ezyang/label/gcc5 -c conda-forge protobuf scipy caffe2
    git clone https://github.com/onnx/onnx-caffe2.git --recurse-submodules --quiet
    # There is some nuance to the strategy here.  In principle,
    # we could check out HEAD versions of *all* our dependencies
    # and see if the whole shebang builds.  But if the build breaks,
    # it is not obvious who is to blame.  A breakage here is
    # not *actionable*, which means it is not useful.
    #
    # So, our strategy is to checkout HEAD of onnx-pytorch (which
    # is supposed to be passing CI), and update only *pytorch*
    # to HEAD.
    #
    # BTW, this means that this is likely to fail of onnx-pytorch
    # is floating some temporary patches that haven't made their
    # way back to PyTorch.  This is by design: merge those patches!
    echo "Installing onnx-pytorch"
    git clone https://github.com/ezyang/onnx-pytorch.git --recurse-submodules --quiet
    (cd onnx-pytorch/onnx && python setup.py install)
    (cd onnx-pytorch/onnx-caffe2 && python setup.py install)
    (cd onnx-pytorch && python setup.py install)
    python onnx-pytorch/test/test_models.py
    python onnx-pytorch/test/test_caffe2.py
fi

echo "Testing pytorch"
export OMP_NUM_THREADS=4
export MKL_NUM_THREADS=4
time test/run_test.sh

echo "Installing torchvision at branch master"
rm -rf vision
git clone https://github.com/pytorch/vision --quiet
pushd vision
conda install -y pillow
time python setup.py install
popd

echo "ALL CHECKS PASSED"

if [ "$OS" == "LINUX" ]; then
    if [ "$GIT_BRANCH" == "origin/master" ]
    then
        if [ $PYTHON_VERSION -eq 3 ]
        then
            echo "Rebuilding and publishing sphinx docs"
	    pip install --upgrade pip
            pip install --upgrade setuptools
            pushd docs
            # cp torchvision docs
            rm -rf source/torchvision
            cp -r ../vision/docs/source source/torchvision
            # Make sure it is uninstalled!
            pip uninstall -y sphinx_rtd_theme || true
            pip uninstall -y sphinx_rtd_theme || true
            pip install -r requirements.txt || true
            make html

            rm -rf tmp
            echo $GITHUB_TOKEN >/tmp/token
            git clone https://pytorchbot:$GITHUB_TOKEN@github.com/pytorch/pytorch.github.io -b master tmp --quiet 2>&1 | grep -v $GITHUB_TOKEN || true
            cd tmp
            git rm -rf docs/master || true
            mv ../build/html docs/master
            find docs/master -name "*.html" -print0 | xargs -0 sed -i -E 's/master[[:blank:]]\([[:digit:]]\.[[:digit:]]\.[[:digit:]]+\+[[:xdigit:]]+[[:blank:]]\)/<a href="http:\/\/pytorch.org\/docs\/versions.html">& \&#x25BC<\/a>/g'
            git add docs/master || true
            git status
            git config user.email "soumith+bot@pytorch.org"
            git config user.name "pytorchbot"
            git commit -m "auto-generating sphinx docs"
            git status
            git push https://pytorchbot:$GITHUB_TOKEN@github.com/pytorch/pytorch.github.io master:master 2>&1 | grep -v $GITHUB_TOKEN || true
            git status
            cd ..
            rm -rf tmp
            echo "Done rebuilding and publishing sphinx docs"
        fi
    fi
fi

# this is needed, i think because of a bug in nimbix-wrapper.py
# otherwise, ALL CHECKS PASSED is not getting printed out sometimes
sleep 10
