@echo off

curl -k -L https://aka.ms/vs/15/release/vs_buildtools.exe --output vs_BuildTools.exe
if errorlevel 1 exit /b 1

start /wait .\vs_buildtools.exe --nocache --norestart --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools
if errorlevel 1 exit /b 1
