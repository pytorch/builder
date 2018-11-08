@echo off

curl -k https://aka.ms/vs/15/release/vs_buildtools.exe --output vs_BuildTools.exe
start /wait .\vs_buildtools.exe --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools
:: --add Microsoft.VisualStudio.Component.VC.Tools.14.11
if errorlevel 1 exit /b 1
