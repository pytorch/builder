set -ex

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters. Pass pytorch or torchvision as the option"
    exit 1
fi

package_name=$1

if [[ "$package_name" == pytorch ]]; then
    echo "Uploading pytorch binaries"
elif [[ "$package_name" == torchvision ]]; then
    echo "Uploading torchvision binaries"
else
    echo "Unknown option $package_name"
    exit 1
fi


pushd winwheels/conda
anaconda upload -u pytorch $package_name*.bz2 --force
popd


pushd winwheels/whl
if [[ "$package_name" == pytorch ]]; then
    whl_name="*torch-*.whl*"
elif [[ "$package_name" == torchvision ]]; then
    whl_name="*torchvision*.whl*"
fi
find . -type f -name "$whl_name" -exec sh -c 'unzip -j {} -d . "*.dist-info/METADATA" && mv METADATA {}.metadata' \;
find . -name "$whl_name" | cut -f 2- -d'/' | xargs -I {} aws s3 cp {} s3://pytorch/whl/{}  --acl public-read
popd


if [[ "$package_name" == pytorch ]]; then
    pushd winwheels/libtorch
    find . -name "*.zip" |  cut -f 2- -d'/' | xargs -I {} aws s3 cp {} s3://pytorch/libtorch/{}  --acl public-read
    popd
fi

# then run
# HTML_NAME=torch_nightly.html PIP_UPLOAD_FOLDER="nightly/" cron/update_s3_htmls.sh
