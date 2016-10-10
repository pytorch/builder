if ! ls /usr/local/cuda-$1
then
    echo "folder /usr/local/cuda-$1 not found to switch"
fi

echo "Switching symlink to /usr/local/cuda-$1"
sudo rm /usr/local/cuda
sudo ln -s /usr/local/cuda-$1 /usr/local/cuda

ls -alh /usr/local/cuda

