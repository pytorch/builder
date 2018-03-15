@echo off

:: Caution: Please don't use this script locally
:: It may destroy your build environment.

setlocal
    
call "%VS15VCVARSALL%" x86_amd64
for /f "usebackq tokens=*" %%i in (`where link.exe`) do move "%%i" "%%i.bak"
    
endlocal
