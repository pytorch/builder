@setlocal

@REM set MAGMA_VERSION=2.5.4

@REM set CUVER_NODOT=%CUDA_VERSION%
@REM set CUVER=%CUVER_NODOT:~0,-1%.%CUVER_NODOT:~-1,1%

@REM set CONFIG_LOWERCASE=%CONFIG:D=d%
@REM set CONFIG_LOWERCASE=%CONFIG_LOWERCASE:R=r%
@REM set CONFIG_LOWERCASE=%CONFIG_LOWERCASE:M=m%

@REM echo Building for configuration: %CONFIG_LOWERCASE%, %CUVER%

@REM :: Download Ninja
@REM curl -k https://s3.amazonaws.com/ossci-windows/ninja_1.8.2.exe --output C:\Tools\ninja.exe
@REM if errorlevel 1 exit /b 1

@REM set "PATH=C:\Tools;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%CUVER%\bin;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%CUVER%\libnvvp;%PATH%"
@REM set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%CUVER%
@REM set NVTOOLSEXT_PATH=C:\Program Files\NVIDIA Corporation\NvToolsExt

@REM mkdir magma_cuda%CUVER_NODOT%
@REM cd magma_cuda%CUVER_NODOT%

@REM if not exist magma (
@REM   :: MAGMA 2.5.4 from http://icl.utk.edu/projectsfiles/magma/downloads/ with applied patches from our magma folder
@REM   git clone https://github.com/peterjc123/magma.git magma
@REM   if errorlevel 1 exit /b 1
@REM ) else (
@REM   rmdir /S /Q magma\build
@REM   rmdir /S /Q magma\install
@REM )

@REM cd magma
@REM mkdir build && cd build

@REM set GPU_TARGET=All
@REM set CUDA_ARCH_LIST= -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70

@REM IF "%CUVER_NODOT%" == "110" (
@REM   set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80"
@REM )

@REM IF "%CUVER_NODOT%" == "111" (
@REM   set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
@REM )

@REM IF "%CUVER_NODOT%" == "112" (
@REM   set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
@REM )

@REM IF "%CUVER_NODOT%" == "113" (
@REM   set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
@REM )

@REM set CC=cl.exe
@REM set CXX=cl.exe

@REM cmake .. -DGPU_TARGET="%GPU_TARGET%" ^
@REM             -DUSE_FORTRAN=0 ^
@REM             -DCMAKE_CXX_FLAGS="/FS /Zf" ^
@REM             -DCMAKE_BUILD_TYPE=%CONFIG% ^
@REM             -DCMAKE_GENERATOR=Ninja ^
@REM             -DCMAKE_INSTALL_PREFIX=..\install\ ^
@REM             -DCUDA_ARCH_LIST="%CUDA_ARCH_LIST%"
@REM if errorlevel 1 exit /b 1

@REM cmake --build . --target install --config %CONFIG% -- -j%NUMBER_OF_PROCESSORS%
@REM if errorlevel 1 exit /b 1

@REM cd ..\..\..

@REM :: Create
@REM 7z a magma_%MAGMA_VERSION%_cuda%CUVER_NODOT%_%CONFIG_LOWERCASE%.7z %cd%\magma_cuda%CUVER_NODOT%\magma\install\*


:: Push to AWS
IF DEFINED WITH_PUSH (
    set AWS_EC2_METADATA_DISABLED=true
    set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
    set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
    @REM aws s3 cp magma_%MAGMA_VERSION%_cuda%CUVER_NODOT%_%CONFIG_LOWERCASE%.7z %OSSCI_WINDOWS_S3% --acl public-read
    echo This is a test> test.txt
    aws s3 cp test.txt %OSSCI_WINDOWS_S3% --acl public-read
    if errorlevel 1 exit /b 1
)

rmdir /S /Q magma_cuda%CUVER_NODOT%\
@endlocal
