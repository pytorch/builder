#!/bin/bash

set -ex

function install_102 {
    echo "Installing CUDA 10.2 and CuDNN"
    rm -rf /usr/local/cuda-10.2 /usr/local/cuda
    # # install CUDA 10.2 in the same container
    wget -q http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run
    chmod +x cuda_10.2.89_440.33.01_linux.run
    ./cuda_10.2.89_440.33.01_linux.run    --extract=/tmp/cuda
    rm -f cuda_10.2.89_440.33.01_linux.run
    mv /tmp/cuda/cuda-toolkit /usr/local/cuda-10.2
    rm -rf /tmp/cuda
    rm -f /usr/local/cuda && ln -s /usr/local/cuda-10.2 /usr/local/cuda

    # install CUDA 10.2 CuDNN
    # cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
    mkdir tmp_cudnn && cd tmp_cudnn
    wget -q http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7-dev_7.6.5.32-1+cuda10.2_amd64.deb -O cudnn-dev.deb
    wget -q http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7_7.6.5.32-1+cuda10.2_amd64.deb -O cudnn.deb
    ar -x cudnn-dev.deb && tar -xvf data.tar.xz
    ar -x cudnn.deb && tar -xvf data.tar.xz
    mkdir -p cuda/include && mkdir -p cuda/lib64
    cp -a usr/include/x86_64-linux-gnu/cudnn_v7.h cuda/include/cudnn.h
    cp -a usr/lib/x86_64-linux-gnu/libcudnn* cuda/lib64
    mv cuda/lib64/libcudnn_static_v7.a cuda/lib64/libcudnn_static.a
    ln -s libcudnn.so.7 cuda/lib64/libcudnn.so
    chmod +x cuda/lib64/*.so
    cp -a cuda/include/* /usr/local/cuda/include/
    cp -a cuda/lib64/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_cudnn
    ldconfig
}

function install_113 {
    echo "Installing CUDA 11.3 and CuDNN 8.2"
    rm -rf /usr/local/cuda-11.3 /usr/local/cuda
    # install CUDA 11.3.1 in the same container
    wget -q https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.19.01_linux.run
    chmod +x cuda_11.3.1_465.19.01_linux.run
    ./cuda_11.3.1_465.19.01_linux.run --toolkit --silent
    rm -f cuda_11.3.1_465.19.01_linux.run
    rm -f /usr/local/cuda && ln -s /usr/local/cuda-11.3 /usr/local/cuda

    # cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
    mkdir tmp_cudnn && cd tmp_cudnn
    wget -q https://developer.download.nvidia.com/compute/redist/cudnn/v8.2.0/cudnn-11.3-linux-x64-v8.2.0.53.tgz -O cudnn-8.2.tgz
    tar xf cudnn-8.2.tgz
    cp -a cuda/include/* /usr/local/cuda/include/
    cp -a cuda/lib64/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_cudnn
    ldconfig
}

function install_115 {
    echo "Installing CUDA 11.5 and CuDNN 8.3"
    rm -rf /usr/local/cuda-11.5 /usr/local/cuda
    # install CUDA 11.5.0 in the same container
    wget -q https://developer.download.nvidia.com/compute/cuda/11.5.0/local_installers/cuda_11.5.0_495.29.05_linux.run
    chmod +x cuda_11.5.0_495.29.05_linux.run
    ./cuda_11.5.0_495.29.05_linux.run --toolkit --silent
    rm -f cuda_11.5.0_495.29.05_linux.run
    rm -f /usr/local/cuda && ln -s /usr/local/cuda-11.5 /usr/local/cuda

    # cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
    mkdir tmp_cudnn && cd tmp_cudnn
    wget -q https://developer.download.nvidia.com/compute/redist/cudnn/v8.3.2/local_installers/11.5/cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz -O cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz
    tar xf cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz
    cp -a cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive/include/* /usr/local/cuda/include/
    cp -a cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive/lib/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_cudnn
    ldconfig
}

function install_116 {
    echo "Installing CUDA 11.6 and CuDNN 8.3"
    rm -rf /usr/local/cuda-11.6 /usr/local/cuda
    # install CUDA 11.6.1 in the same container
    wget -q https://developer.download.nvidia.com/compute/cuda/11.6.1/local_installers/cuda_11.6.1_510.47.03_linux.run
    chmod +x cuda_11.6.1_510.47.03_linux.run
    ./cuda_11.6.1_510.47.03_linux.run --toolkit --silent
    rm -f cuda_11.6.1_510.47.03_linux.run
    rm -f /usr/local/cuda && ln -s /usr/local/cuda-11.6 /usr/local/cuda

    # cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
    mkdir tmp_cudnn && cd tmp_cudnn
    wget -q https://developer.download.nvidia.com/compute/redist/cudnn/v8.3.2/local_installers/11.5/cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz -O cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz
    tar xf cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz
    cp -a cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive/include/* /usr/local/cuda/include/
    cp -a cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive/lib/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_cudnn
    ldconfig
}

function prune_102 {
    echo "Pruning CUDA 10.2 and CuDNN"
    #####################################################################################
    # CUDA 10.2 prune static libs
    #####################################################################################
    export NVPRUNE="/usr/local/cuda-10.2/bin/nvprune"
    export CUDA_LIB_DIR="/usr/local/cuda-10.2/lib64"

    export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"
    export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"

    if [[ -n "$OVERRIDE_GENCODE" ]]; then
        export GENCODE=$OVERRIDE_GENCODE
    fi

    # all CUDA libs except CuDNN and CuBLAS (cudnn and cublas need arch 3.7 included)
    ls $CUDA_LIB_DIR/ | grep "\.a" | grep -v "culibos" | grep -v "cudart" | grep -v "cudnn" | grep -v "cublas" | grep -v "metis"  \
	| xargs -I {} bash -c \
		"echo {} && $NVPRUNE $GENCODE $CUDA_LIB_DIR/{} -o $CUDA_LIB_DIR/{}"

    # prune CuDNN and CuBLAS
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcudnn_static.a -o $CUDA_LIB_DIR/libcudnn_static.a
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublas_static.a -o $CUDA_LIB_DIR/libcublas_static.a
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublasLt_static.a -o $CUDA_LIB_DIR/libcublasLt_static.a

    #####################################################################################
    # CUDA 10.2 prune visual tools
    #####################################################################################
    export CUDA_BASE="/usr/local/cuda-10.2/"
    rm -rf $CUDA_BASE/libnsight $CUDA_BASE/libnvvp $CUDA_BASE/nsightee_plugins $CUDA_BASE/nsight-compute-2019.5.0 $CUDA_BASE/nsight-systems-2019.5.2

}

function prune_113 {
    echo "Pruning CUDA 11.3 and CuDNN"
    #####################################################################################
    # CUDA 11.3 prune static libs
    #####################################################################################
    export NVPRUNE="/usr/local/cuda-11.3/bin/nvprune"
    export CUDA_LIB_DIR="/usr/local/cuda-11.3/lib64"

    export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
    export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"

    if [[ -n "$OVERRIDE_GENCODE" ]]; then
        export GENCODE=$OVERRIDE_GENCODE
    fi

    # all CUDA libs except CuDNN and CuBLAS (cudnn and cublas need arch 3.7 included)
    ls $CUDA_LIB_DIR/ | grep "\.a" | grep -v "culibos" | grep -v "cudart" | grep -v "cudnn" | grep -v "cublas" | grep -v "metis"  \
      | xargs -I {} bash -c \
		"echo {} && $NVPRUNE $GENCODE $CUDA_LIB_DIR/{} -o $CUDA_LIB_DIR/{}"

    # prune CuDNN and CuBLAS
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcudnn_static.a -o $CUDA_LIB_DIR/libcudnn_static.a
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublas_static.a -o $CUDA_LIB_DIR/libcublas_static.a
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublasLt_static.a -o $CUDA_LIB_DIR/libcublasLt_static.a

    #####################################################################################
    # CUDA 11.3 prune visual tools
    #####################################################################################
    export CUDA_BASE="/usr/local/cuda-11.3/"
    rm -rf $CUDA_BASE/libnvvp $CUDA_BASE/nsightee_plugins $CUDA_BASE/nsight-compute-2021.1.0 $CUDA_BASE/nsight-systems-2021.1.3
}

function prune_115 {
    echo "Pruning CUDA 11.5 and CuDNN"
    #####################################################################################
    # CUDA 11.3 prune static libs
    #####################################################################################
    export NVPRUNE="/usr/local/cuda-11.5/bin/nvprune"
    export CUDA_LIB_DIR="/usr/local/cuda-11.5/lib64"

    export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
    export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"

    if [[ -n "$OVERRIDE_GENCODE" ]]; then
        export GENCODE=$OVERRIDE_GENCODE
    fi

    # all CUDA libs except CuDNN and CuBLAS (cudnn and cublas need arch 3.7 included)
    ls $CUDA_LIB_DIR/ | grep "\.a" | grep -v "culibos" | grep -v "cudart" | grep -v "cudnn" | grep -v "cublas" | grep -v "metis"  \
      | xargs -I {} bash -c \
		"echo {} && $NVPRUNE $GENCODE $CUDA_LIB_DIR/{} -o $CUDA_LIB_DIR/{}"

    # prune CuDNN and CuBLAS
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublas_static.a -o $CUDA_LIB_DIR/libcublas_static.a
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublasLt_static.a -o $CUDA_LIB_DIR/libcublasLt_static.a

    #####################################################################################
    # CUDA 11.5 prune visual tools
    #####################################################################################
    export CUDA_BASE="/usr/local/cuda-11.5/"
    rm -rf $CUDA_BASE/libnvvp $CUDA_BASE/nsightee_plugins $CUDA_BASE/nsight-compute-2021.3.0 $CUDA_BASE/nsight-systems-2021.3.3
}

function prune_116 {
    echo "Pruning CUDA 11.6 and CuDNN"
    #####################################################################################
    # CUDA 11.6 prune static libs
    #####################################################################################
    export NVPRUNE="/usr/local/cuda-11.6/bin/nvprune"
    export CUDA_LIB_DIR="/usr/local/cuda-11.6/lib64"

    export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
    export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"

    if [[ -n "$OVERRIDE_GENCODE" ]]; then
        export GENCODE=$OVERRIDE_GENCODE
    fi

    # all CUDA libs except CuDNN and CuBLAS (cudnn and cublas need arch 3.7 included)
    ls $CUDA_LIB_DIR/ | grep "\.a" | grep -v "culibos" | grep -v "cudart" | grep -v "cudnn" | grep -v "cublas" | grep -v "metis"  \
      | xargs -I {} bash -c \
                "echo {} && $NVPRUNE $GENCODE $CUDA_LIB_DIR/{} -o $CUDA_LIB_DIR/{}"

    # prune CuDNN and CuBLAS
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublas_static.a -o $CUDA_LIB_DIR/libcublas_static.a
    $NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublasLt_static.a -o $CUDA_LIB_DIR/libcublasLt_static.a

    #####################################################################################
    # CUDA 11.6 prune visual tools
    #####################################################################################
    export CUDA_BASE="/usr/local/cuda-11.6/"
    rm -rf $CUDA_BASE/libnvvp $CUDA_BASE/nsightee_plugins $CUDA_BASE/nsight-compute-2022.1.1 $CUDA_BASE/nsight-systems-2021.5.2
} 

# idiomatic parameter and option handling in sh
while test $# -gt 0
do
    case "$1" in
	10.2) install_102; prune_102
		;;
    11.3) install_113; prune_113
		;;
    11.5) install_115; prune_115
		;;
    11.6) install_116; prune_116
	        ;;
	*) echo "bad argument $1"; exit 1
	   ;;
    esac
    shift
done
