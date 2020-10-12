@echo ON

rem Copy over the bin, include and lib dirs
robocopy %SRC_DIR%\bin\ %LIBRARY_BIN%\ *.* /E /XC /XN /XO
if %ERRORLEVEL% GEQ 8 exit 1


robocopy %SRC_DIR%\include\ %LIBRARY_INC%\ *.* /E
if %ERRORLEVEL% GEQ 8 exit 1

robocopy %SRC_DIR%\lib\ %LIBRARY_LIB%\ *.* /E
if %ERRORLEVEL% GEQ 8 exit 1

rem Add the licences to the recipe directory
copy "%SRC_DIR%\README.txt" "%RECIPE_DIR%"
mkdir "%RECIPE_DIR%\licenses"
copy "%SRC_DIR%\licenses" "%RECIPE_DIR%\licenses"

exit 0
