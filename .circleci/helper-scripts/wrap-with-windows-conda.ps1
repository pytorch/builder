param(
[string]$a
)

# TODO Not sure if this actually works for PowerShell:
$ErrorActionPreference = "Stop"


choco install miniconda3
$env:PATH = "C:\tools\miniconda3;C:\tools\miniconda3\Library\usr\bin;C:\tools\miniconda3\Scripts;C:\tools\miniconda3\bin" + $env:PATH
conda install -yq conda-build


# This is a workaround for failures in all of the following projects:
# fast_neural_style, reinforcement_learning, block, parlai, pennylane, skorch, tensorly
#
# See: https://github.com/ContinuumIO/anaconda-issues/issues/10884#issuecomment-527888521
conda update -c defaults python
$Env:CONDA_DLL_SEARCH_MODIFICATION_ENABLE += 1

#echo "About to run conda env remove on: env$PYTHON_VERSION"
#conda env remove -n "env$PYTHON_VERSION"


#echo "Just ran conda env remove on: env$PYTHON_VERSION"
#echo "About to run conda create -yn on: env$PYTHON_VERSION"

#conda create -yn "env$PYTHON_VERSION" python="$PYTHON_VERSION"

#echo "Just ran conda create -yn on: env$PYTHON_VERSION"


#echo "Current python version before activation:"
#python --version

echo "About to run: bash $a"
bash $a

# Required to propagate bash error out of Powershell:
exit $LastExitCode
