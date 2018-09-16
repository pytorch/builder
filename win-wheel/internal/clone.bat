@echo off

git clone --recursive https://github.com/pytorch/pytorch

cd pytorch

git checkout tags/v%PYTORCH_BUILD_VERSION%
