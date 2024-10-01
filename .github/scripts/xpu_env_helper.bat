call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"

set args=%1
shift
:start
if [%1] == [] goto done
set args=%args% %1
shift
goto start

:done
if "%args%" == "" (
    echo Usage: xpu_env_helper.bat [command] [args]
    echo e.g. xpu_env_helper.bat icpx --version
)

%args% || exit /b 1
