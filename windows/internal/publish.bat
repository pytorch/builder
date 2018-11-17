@echo off

set SRC_DIR=%~dp0
pushd %SRC_DIR%

if NOT "%CUDA_VERSION%" == "cpu" (
    set PACKAGE_SUFFIX=_cuda%CUDA_VERSION%
) else (
    set PACKAGE_SUFFIX=
)

set PUBLISH_BRANCH=%PACKAGE%_%DESIRED_PYTHON%%PACKAGE_SUFFIX%

git clone %ARTIFACT_REPO_URL% -b %PUBLISH_BRANCH% --single-branch > nul 2>&1

IF ERRORLEVEL 1 (
    echo Branch %PUBLISH_BRANCH% not exist, falling back to master
    set NO_BRANCH=1
    git clone %ARTIFACT_REPO_URL% -b master --single-branch > nul 2>&1
)

IF ERRORLEVEL 1 (
    echo Clone failed
    goto err
)

cd pytorch_builder
attrib -s -h -r . /s /d

IF "%NO_BRANCH%" == "1" (
    :: Empty if not exist
    rd /s /q .
) ELSE (
    :: Otherwise update it
    rmdir /s /q .git
)

:: Reset errorlevel
ver >nul

IF NOT EXIST %PACKAGE% mkdir %PACKAGE%

xcopy /S /E /Y ..\..\output\*.* %PACKAGE%\

git config --global user.name "Azure DevOps"
git config --global user.email peterghost86@gmail.com
git init
git checkout --orphan %PUBLISH_BRANCH%
git remote add origin %ARTIFACT_REPO_URL%
git add .
git commit -m "Update artifacts"

:push

if "%RETRY_TIMES%" == "" (
    set /a RETRY_TIMES=3
) else (
    set /a RETRY_TIMES=%RETRY_TIMES%-1
)

git push origin %PUBLISH_BRANCH%% -f > nul 2>&1

IF ERRORLEVEL 1 (
    echo Git push retry times remaining: %RETRY_TIMES%
    IF %RETRY_TIMES% EQU 0 (
        echo Push failed
        goto err
    )
    goto push
)

popd

exit /b 0

:err

popd

exit /b 1
