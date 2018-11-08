@echo off

curl -k https://aka.ms/vs/15/release/vs_buildtools.exe --output vs_BuildTools.exe
echo https://aka.ms/vs/15/release/channel > VisualStudio.chman
mkdir vs2017
start /wait .\vs_buildtools.exe --nocache --norestart --quiet --wait
        --add Microsoft.VisualStudio.Workload.VCTools `
        --installPath "%CD%\vs2017" `
        --channelUri "%CD%\VisualStudio.chman" `
        --installChannelUri "%CD%\VisualStudio.chman"
:: --add Microsoft.VisualStudio.Component.VC.Tools.14.11
if errorlevel 1 exit /b 1
