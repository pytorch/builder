@echo off

git clone https://github.com/%PYTORCH_REPO%/pytorch

cd pytorch

IF "%PYTORCH_BRANCH%" == "" (
    set PYTORCH_BRANCH=v%PYTORCH_BUILD_VERSION%
)
git checkout tags/%PYTORCH_BRANCH%
IF ERRORLEVEL 1 git checkout %PYTORCH_BRANCH%

git submodule update --init --recursive
IF ERRORLEVEL 1 exit /b 1
