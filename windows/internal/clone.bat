@echo off

git clone --recursive https://github.com/pytorch/pytorch

cd pytorch

git checkout tags/v%PYTORCH_BUILD_VERSION%
IF ERRORLEVEL 1 git checkout v%PYTORCH_BUILD_VERSION%
