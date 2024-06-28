#!/bin/bash
set -ex

# MKL
MKL_VERSION=2022.2.1

# Install Python packages depending on the base OS
ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
case "$ID" in
  ubuntu)
    # TODO (1)
    UBUNTU_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
    apt-get update
    apt-get install -y unzip
    ;;
  centos)
    yum update -y
    yum install -y unzip
    ;;
  *)
    echo "Unable to determine OS..."
    exit 1
    ;;
esac

mkdir -p /opt/intel/
pushd /tmp

python3 -mpip download -d . mkl-static==${MKL_VERSION}
unzip mkl_static-${MKL_VERSION}-py2.py3-none-manylinux1_x86_64.whl
unzip mkl_include-${MKL_VERSION}-py2.py3-none-manylinux1_x86_64.whl
mv mkl_static-${MKL_VERSION}.data/data/lib /opt/intel/
mv mkl_include-${MKL_VERSION}.data/data/include/ /opt/intel/
