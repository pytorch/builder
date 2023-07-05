set -ex

# N.B. this is hardcoded to cpu, as at the time of writing Mac builds are cpu
# only

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)

# These defaults correspond to wheel/build_wheel.sh
if [[ -z "$MAC_WHEEL_FINAL_FOLDER" ]]; then
    MAC_WHEEL_FINAL_FOLDER='whl'
fi
if [[ -z "$MAC_LIBTORCH_FINAL_FOLDER" ]]; then
    MAC_LIBTORCH_FINAL_FOLDER='libtorch'
fi


# Upload wheels to s3
if [[ -d "$MAC_WHEEL_FINAL_FOLDER" ]]; then
    pushd "$MAC_WHEEL_FINAL_FOLDER"
    s3_dir="s3://pytorch/whl/${PIP_UPLOAD_FOLDER}cpu/"
    find . -type f -exec sh -c 'unzip -j {} -d . "*.dist-info/METADATA" && mv METADATA {}.metadata' \;
    echo "Uploading all of: $(ls $MAC_WHEEL_FINAL_FOLDER) to $s3_dir"
    ls . | xargs -I {} aws s3 cp {} "$s3_dir" --acl public-read
fi

# Upload libtorch packages to s3
if [[ -d "$MAC_LIBTORCH_FINAL_FOLDER" ]]; then
    pushd "$MAC_LIBTORCH_FINAL_FOLDER"
    s3_dir="s3://pytorch/libtorch/${PIP_UPLOAD_FOLDER}cpu/"
    echo "Uploading all of: $(ls $MAC_LIBTORCH_FINAL_FOLDER) to $s3_dir"
    ls . | xargs -I {} aws s3 cp {} "$s3_dir" --acl public-read
    popd
fi
