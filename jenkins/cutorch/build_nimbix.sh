
echo "here in build_nimbix"

set -e

PROJECT=$1
GIT_COMMIT=$2
GIT_BRANCH=$3

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
    echo "Downloading CUDA"
    wget -c http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run -O ~/cuda_7.5.18_linux.run

    echo "Installing CUDA"
    chmod +x ~/cuda_7.5.18_linux.run
    sudo bash ~/cuda_7.5.18_linux.run --silent --toolkit --no-opengl-libs

    echo "\nDone installing CUDA"
else
    echo "CUDA already installed"
fi

echo "nvcc: $(which nvcc)"

echo "Checking Torch"

distro_remote_hash=$(git ls-remote https://github.com/torch/distro HEAD|cut -f1)
pushd ~/torch >/dev/null
distro_local_hash=$(git rev-parse HEAD)
popd >/dev/null

if [ "$distro_remote_hash" != "$distro_local_hash" ]
then
    echo "Torch needs to be reinstalled. Local commit is $distro_local_hash but remote HEAD is $distro_remote_hash"
    rm -rf ~/torch
    git clone https://github.com/torch/distro.git ~/torch --quiet --recursive 

    pushd ~/torch
    bash install-deps 2>&1 >/dev/null
    ./install.sh -s
    popd

else
    echo "Torch is already updated to the latest at hash $distro_local_hash"
fi

source ~/torch/install/bin/torch-activate
echo "PATH=$PATH"

echo "Done installing Torch"

echo "Installing $PROJECT at branch $GIT_BRANCH and commit $GIT_COMMIT"
rm -rf cutorch
git clone https://github.com/torch/cutorch --quiet 
cd cutorch
git -c core.askpass=true fetch --tags https://github.com/torch/cutorch +refs/pull/*:refs/remotes/origin/pr/* --quiet
git checkout $GIT_BRANCH
time luarocks make rocks/cutorch-scm-1.rockspec 2>&1

echo "Testing cutorch"
time luajit -lcutorch -e "cutorch.test()" 2>&1

echo "ALL CHECKS PASSED"

# this is needed, i think because of a bug in nimbix-wrapper.py
# otherwise, ALL CHECKS PASSED is not getting printed out sometimes
sleep 10
