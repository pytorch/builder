call windows/internal/vc_install_helper.bat
if errorlevel 1 exit /b 1

call windows/internal/cuda_install.bat
if errorlevel 1 exit /b 1

bash ./conda/build_pytorch.sh %CUDA_VERSION% %PYTORCH_BUILD_VERSION% %PYTORCH_BUILD_NUMBER%
if errorlevel 1 exit /b 1
