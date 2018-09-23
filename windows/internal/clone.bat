@echo off

git clone --recursive https://github.com/pytorch/pytorch

cd pytorch

IF "%PYTORCH_REPO%" == "" (
    set PYTORCH_REPO=v%PYTORCH_BUILD_VERSION%
)
git checkout tags/%PYTORCH_REPO%
IF ERRORLEVEL 1 git checkout %PYTORCH_REPO%
