set -ex

# N.B. this is hardcoded to cpu, as at the time of writing Mac builds are cpu
# only

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)

# N.B. MAC_PACKAGE_FINAL_FOLDER will probably be an absolute path, so it should
# not be inserted into the s3 path.

if [[ -z "$BUILD_PYTHONLESS" ]]; then
    if [[ -z "$MAC_PACKAGE_FINAL_FOLDER" ]]; then
        MAC_PACKAGE_FINAL_FOLDER='whl'
    fi
    s3_dir="s3://pytorch/whl/${PIP_UPLOAD_FOLDER}cpu/"
else
    if [[ -z "$MAC_PACKAGE_FINAL_FOLDER" ]]; then
        MAC_PACKAGE_FINAL_FOLDER='libtorch_packages'
    fi
    s3_dir="s3://pytorch/libtorch_packages/${PIP_UPLOAD_FOLDER}cpu/"
fi


# Upload the wheels to s3
# N.B. this is hardcoded to match wheel/build_wheel.sh, which copies built
# wheels to this folder
echo "Uploading all of: $(ls $MAC_PACKAGE_FINAL_FOLDER) to $s3_dir"
ls "$MAC_PACKAGE_FINAL_FOLDER" | xargs -I {} aws s3 cp "$MAC_PACKAGE_FINAL_FOLDER"/{} "$s3_dir" --acl public-read
