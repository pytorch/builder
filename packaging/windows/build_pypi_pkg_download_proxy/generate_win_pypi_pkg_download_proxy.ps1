param(
    [string]$torchVer
)

$setupFile = "setup.py"
$replaceKeyword = "{{GENERATE_TORCH_PKG_VER}}"

mkdir torch
Copy $setupFile torch/
cd torch

(Get-Content $setupFile).replace($replaceKeyword, $torchVer) | Set-Content $setupFile

& python $setupFile sdist

Write-Host "Generate package under torch/dist"


