@echo off

set PYTORCH_BUILD_VERSION=0.3.1

git clone --recursive https://github.com/pytorch/pytorch

cd pytorch

git checkout tags/v%PYTORCH_BUILD_VERSION%
xcopy /Y aten\src\ATen\common_with_cwrap.py tools\shared\cwrap_common.py
