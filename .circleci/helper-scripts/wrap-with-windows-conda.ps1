param(
[string]$a
)

choco install miniconda3
$env:PATH = "C:\tools\miniconda3;C:\tools\miniconda3\Library\usr\bin;C:\tools\miniconda3\Scripts;C:\tools\miniconda3\bin" + $env:PATH
conda install -yq conda-build

#echo "About to run conda env remove on: env$PYTHON_VERSION"
#conda env remove -n "env$PYTHON_VERSION"


#echo "Just ran conda env remove on: env$PYTHON_VERSION"
#echo "About to run conda create -yn on: env$PYTHON_VERSION"

#conda create -yn "env$PYTHON_VERSION" python="$PYTHON_VERSION"

#echo "Just ran conda create -yn on: env$PYTHON_VERSION"


#echo "Current python version before activation:"
#python --version

echo "About to run: bash packaging/build_conda.sh $a"
bash packaging/build_conda.sh $a
