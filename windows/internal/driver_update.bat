set "DRIVER_DOWNLOAD_LINK=https://ossci-windows.s3.amazonaws.com/452.39-data-center-tesla-desktop-win10-64bit-international.exe"
curl --retry 3 -kL %DRIVER_DOWNLOAD_LINK% --output 452.39-data-center-tesla-desktop-win10-64bit-international.exe
if errorlevel 1 exit /b 1

start /wait 452.39-data-center-tesla-desktop-win10-64bit-international.exe -s -noreboot
if errorlevel 1 exit /b 1

del 452.39-data-center-tesla-desktop-win10-64bit-international.exe || ver > NUL
