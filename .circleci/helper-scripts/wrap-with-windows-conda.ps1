param(
[string]$a
)

choco install miniconda3
$env:PATH = "C:\tools\miniconda3;C:\tools\miniconda3\Library\usr\bin;C:\tools\miniconda3\Scripts;C:\tools\miniconda3\bin" + $env:PATH
conda install -yq conda-build
bash packaging/build_conda.sh $a
