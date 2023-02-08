#!/bin/bash

set -ex

function install_116 {
    echo "Installing CUDA 11.6 and CuDNN 8.3"
    rm -rf /usr/local/cuda-11.6 /usr/local/cuda
    # install CUDA 11.6.2 in the same container
    wget -q https://developer.download.nvidia.com/compute/cuda/11.6.2/local_installers/cuda_11.6.2_510.47.03_linux.run
    chmod +x cuda_11.6.2_510.47.03_linux.run
    ./cuda_11.6.2_510.47.03_linux.run --toolkit --silent
    rm -f cuda_11.6.2_510.47.03_linux.run
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

function install_117 {
    echo "Installing CUDA 11.7 and CuDNN 8.5 and NCCL 2.14"
    rm -rf /usr/local/cuda-11.7 /usr/local/cuda
    # install CUDA 11.7.0 in the same container
    wget -q https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_515.43.04_linux.run
    chmod +x cuda_11.7.0_515.43.04_linux.run
    ./cuda_11.7.0_515.43.04_linux.run --toolkit --silent
    rm -f cuda_11.7.0_515.43.04_linux.run
    rm -f /usr/local/cuda && ln -s /usr/local/cuda-11.7 /usr/local/cuda

    # cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
    mkdir tmp_cudnn && cd tmp_cudnn
    wget -q https://ossci-linux.s3.amazonaws.com/cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz -O cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz
    tar xf cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz
    cp -a cudnn-linux-x86_64-8.5.0.96_cuda11-archive/include/* /usr/local/cuda/include/
    cp -a cudnn-linux-x86_64-8.5.0.96_cuda11-archive/lib/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_cudnn
    ldconfig

    # NCCL license: https://docs.nvidia.com/deeplearning/nccl/#licenses
    mkdir tmp_nccl && cd tmp_nccl
    wget -q https://developer.download.nvidia.com/compute/redist/nccl/v2.14/nccl_2.14.3-1+cuda11.7_x86_64.txz
    tar xf nccl_2.14.3-1+cuda11.7_x86_64.txz
    cp -a nccl_2.14.3-1+cuda11.7_x86_64/include/* /usr/local/cuda/include/
    cp -a nccl_2.14.3-1+cuda11.7_x86_64/lib/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_nccl
    ldconfig
}

function install_118 {
    echo "Installing CUDA 11.8 and cuDNN 8.7 and NCCL 2.15"
    rm -rf /usr/local/cuda-11.8 /usr/local/cuda
    # install CUDA 11.8.0 in the same container
    wget -q https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run
    chmod +x cuda_11.8.0_520.61.05_linux.run
    ./cuda_11.8.0_520.61.05_linux.run --toolkit --silent
    rm -f cuda_11.8.0_520.61.05_linux.run
    rm -f /usr/local/cuda && ln -s /usr/local/cuda-11.8 /usr/local/cuda

    # cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
    mkdir tmp_cudnn && cd tmp_cudnn
    wget -q https://developer.download.nvidia.com/compute/redist/cudnn/v8.7.0/local_installers/11.8/cudnn-linux-x86_64-8.7.0.84_cuda11-archive.tar.xz -O cudnn-linux-x86_64-8.7.0.84_cuda11-archive.tar.xz
    tar xf cudnn-linux-x86_64-8.7.0.84_cuda11-archive.tar.xz
    cp -a cudnn-linux-x86_64-8.7.0.84_cuda11-archive/include/* /usr/local/cuda/include/
    cp -a cudnn-linux-x86_64-8.7.0.84_cuda11-archive/lib/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_cudnn
    ldconfig

    # NCCL license: https://docs.nvidia.com/deeplearning/nccl/#licenses
    mkdir tmp_nccl && cd tmp_nccl
    wget -q https://developer.download.nvidia.com/compute/redist/nccl/v2.15.5/nccl_2.15.5-1+cuda11.8_x86_64.txz
    tar xf nccl_2.15.5-1+cuda11.8_x86_64.txz
    cp -a nccl_2.15.5-1+cuda11.8_x86_64/include/* /usr/local/cuda/include/
    cp -a nccl_2.15.5-1+cuda11.8_x86_64/lib/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_nccl
    ldconfig
}

function install_120 {
    echo "Installing CUDA 12.0 and cuDNN 8.8 and NCCL 2.16"
    rm -rf /usr/local/cuda-12.0 /usr/local/cuda
    # install CUDA 12.0.0 in the same container
    wget -q https://developer.download.nvidia.com/compute/cuda/12.0.1/local_installers/cuda_12.0.1_525.85.12_linux.run
    chmod +x cuda_12.0.1_525.85.12_linux.run
    ./cuda_12.0.1_525.85.12_linux.run --toolkit --silent
    rm -f cuda_12.0.1_525.85.12_linux.run
    rm -f /usr/local/cuda && ln -s /usr/local/cuda-12.0 /usr/local/cuda

    # cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
    mkdir tmp_cudnn && cd tmp_cudnn
    wget -q https://developer.download.nvidia.com/compute/redist/cudnn/v8.8.0/local_installers/12.0/cudnn-linux-x86_64-8.8.0.121_cuda12-archive.tar.xz -O cudnn-linux-x86_64-8.8.0.121_cuda12-archive.tar.xz
    tar xf cudnn-linux-x86_64-8.8.0.121_cuda12-archive.tar.xz
    cp -a cudnn-linux-x86_64-8.8.0.121_cuda12-archive/include/* /usr/local/cuda/include/
    cp -a cudnn-linux-x86_64-8.8.0.121_cuda12-archive/lib/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_cudnn
    ldconfig

    # NCCL license: https://docs.nvidia.com/deeplearning/nccl/#licenses
    mkdir tmp_nccl && cd tmp_nccl
    wget -q https://developer.download.nvidia.com/compute/redist/nccl/v2.16.2/nccl_2.16.2-1+cuda12.0_x86_64.txz
    tar xf nccl_2.16.2-1+cuda12.0_x86_64
    cp -a nccl_2.16.2-1+cuda12.0_x86_64/include/* /usr/local/cuda/include/
    cp -a nccl_2.16.2-1+cuda12.0_x86_64/lib/* /usr/local/cuda/lib64/
    cd ..
    rm -rf tmp_nccl
    ldconfig
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

function prune_117 {
    echo "Pruning CUDA 11.7 and CuDNN"
    #####################################################################################
    # CUDA 11.7 prune static libs
    #####################################################################################
    export NVPRUNE="/usr/local/cuda-11.7/bin/nvprune"
    export CUDA_LIB_DIR="/usr/local/cuda-11.7/lib64"

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
    export CUDA_BASE="/usr/local/cuda-11.7/"
    rm -rf $CUDA_BASE/libnvvp $CUDA_BASE/nsightee_plugins $CUDA_BASE/nsight-compute-2022.2.0 $CUDA_BASE/nsight-systems-2022.1.3
}

function prune_118 {
    echo "Pruning CUDA 11.8 and cuDNN"
    #####################################################################################
    # CUDA 11.8 prune static libs
    #####################################################################################
    export NVPRUNE="/usr/local/cuda-11.8/bin/nvprune"
    export CUDA_LIB_DIR="/usr/local/cuda-11.8/lib64"

    export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86 -gencode arch=compute_90,code=sm_90"
    export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86 -gencode arch=compute_90,code=sm_90"

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
    # CUDA 11.8 prune visual tools
    #####################################################################################
    export CUDA_BASE="/usr/local/cuda-11.8/"
    rm -rf $CUDA_BASE/libnvvp $CUDA_BASE/nsightee_plugins $CUDA_BASE/nsight-compute-2022.3.0 $CUDA_BASE/nsight-systems-2022.4.2/
}


function prune_120 {
    echo "Pruning CUDA 12.0 and cuDNN"
    #####################################################################################
    # CUDA 12.0 prune static libs
    #####################################################################################
    export NVPRUNE="/usr/local/cuda-12.0/bin/nvprune"
    export CUDA_LIB_DIR="/usr/local/cuda-12.0/lib64"

    export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86 -gencode arch=compute_90,code=sm_90"
    export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86 -gencode arch=compute_90,code=sm_90"

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
    # CUDA 12.0 prune visual tools
    #####################################################################################
    export CUDA_BASE="/usr/local/cuda-12.0/"
    rm -rf $CUDA_BASE/libnvvp $CUDA_BASE/nsightee_plugins $CUDA_BASE/nsight-compute-2022.4.1.6 $CUDA_BASE/nsight-systems-2022.4.2.50/
}

# idiomatic parameter and option handling in sh
while test $# -gt 0
do
    case "$1" in
    11.6) install_116; prune_116
	        ;;
    11.7) install_117; prune_117
	        ;;
    11.8) install_118; prune_118
	        ;;
	  12.0) install_120; prune_120
	        ;;
	*) echo "bad argument $1"; exit 1
	   ;;
    esac
    shift
done
