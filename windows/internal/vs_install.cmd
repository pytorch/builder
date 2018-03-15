@echo off

curl -k https://www.dropbox.com/s/spq7vtfb6uxgo0m/vs_BuildTools.exe?dl=1 --output vs_BuildTools.exe
start /wait .\vs_buildtools.exe --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.14.11
