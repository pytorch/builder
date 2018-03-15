@echo off

set SRC_DIR=%~dp0
pushd %SRC_DIR%

set PUBLISH_BRANCH=%PACKAGE%_%DESIRED_PYTHON%

git clone %ARTIFACT_REPO_URL% > nul 2>&1

IF ERRORLEVEL 1 (
    echo Clone failed
    exit /b 1
)

cd pytorch_builder
attrib -s -h -r . /s /d

git checkout %PUBLISH_BRANCH%

IF ERRORLEVEL 1 (
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
git push origin %PUBLISH_BRANCH%% -f

popd

IF ERRORLEVEL 1 (
    echo Push failed
    exit /b 1
)
