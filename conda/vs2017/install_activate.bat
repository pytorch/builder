set YEAR=2017
set VER=15

mkdir "%PREFIX%\etc\conda\activate.d"
copy "%RECIPE_DIR%\activate.bat" "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"

if "%cross_compiler_target_platform%" == "win-64" (
  set "target_platform=amd64"
  echo set "CMAKE_GENERATOR=Visual Studio %VER% %YEAR% Win64" >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
  echo pushd "%%VSINSTALLDIR%%" >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
  if "%VSDEVCMD_ARGS%" == "" (
    echo call "VC\Auxiliary\Build\vcvarsall.bat" x64 >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
  ) else (
    echo call "VC\Auxiliary\Build\vcvarsall.bat" x64 %VSDEVCMD_ARGS% >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
  )
  echo popd >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
) else (
  set "target_platform=x86"
  echo set "CMAKE_GENERATOR=Visual Studio %VER% %YEAR%" >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
  echo pushd "%%VSINSTALLDIR%%" >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
  echo call "VC\Auxiliary\Build\vcvars32.bat" >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
  echo popd >> "%PREFIX%\etc\conda\activate.d\vs%YEAR%_compiler_vars.bat"
)

