set "DRIVER_DOWNLOAD_LINK=https://s3.amazonaws.com/ossci-windows/442.50-tesla-desktop-winserver-2019-2016-international.exe"
curl --retry 3 -kL %DRIVER_DOWNLOAD_LINK% --output 442.50-tesla-desktop-winserver-2019-2016-international.exe
if errorlevel 1 exit /b 1

start /wait 442.50-tesla-desktop-winserver-2019-2016-international.exe -s -noreboot
if errorlevel 1 exit /b 1

del 442.50-tesla-desktop-winserver-2019-2016-international.exe || ver > NUL
