#!/bin/bash

set -ex

function install_nvpl {
    
    mkdir /usr/local/nvpl-lib /usr/local/nvpl-include

    wget https://developer.download.nvidia.com/compute/nvpl/redist/nvpl_blas/linux-sbsa/nvpl_blas-linux-sbsa-0.3.0-archive.tar.xz
    tar xf nvpl_blas-linux-sbsa-0.3.0-archive.tar.xz
    cp -r nvpl_blas-linux-sbsa-0.3.0-archive/lib/* /usr/local/nvpl-lib/
    cp -r nvpl_blas-linux-sbsa-0.3.0-archive/include/* /usr/local/nvpl-include/

    wget https://developer.download.nvidia.com/compute/nvpl/redist/nvpl_lapack/linux-sbsa/nvpl_lapack-linux-sbsa-0.2.3.1-archive.tar.xz
    tar xf nvpl_lapack-linux-sbsa-0.2.3.1-archive.tar.xz
    cp -r nvpl_lapack-linux-sbsa-0.2.3.1-archive/lib/* /usr/local/nvpl-lib/
    cp -r nvpl_lapack-linux-sbsa-0.2.3.1-archive/include/* /usr/local/nvpl-include/
}

install_nvpl