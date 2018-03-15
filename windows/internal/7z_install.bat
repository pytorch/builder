@echo off

set "PATH=%CONDA%\Scripts;%PATH%"
conda install -y --no-deps -c peterjc123 7z
if errorlevel 1 exit /b 1
