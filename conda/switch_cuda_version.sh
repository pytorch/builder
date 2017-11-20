if ! ls /usr/local/cuda-$1
then
    echo "folder /usr/local/cuda-$1 not found to switch"
fi

echo "Switching symlink to /usr/local/cuda-$1"
rm -f /usr/local/cuda
ln -s /usr/local/cuda-$1 /usr/local/cuda
export CUDA_VERSION=$(ls /usr/local/cuda/lib64/libcudart.so.*|sort|tac | head -1 | rev | cut -d"." -f -3 | rev)
export CUDNN_VERSION=$(ls /usr/local/cuda/lib64/libcudnn.so.*|sort|tac | head -1 | rev | cut -d"." -f -3 | rev)

ls -alh /usr/local/cuda

echo "CUDA_VERSION=$CUDA_VERSION"
echo "CUDNN_VERSION=$CUDNN_VERSION"
