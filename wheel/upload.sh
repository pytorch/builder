set -ex

# N.B. this is hardcoded to cpu, as at the time of writing Mac builds are cpu
# only

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)

if [[ -z "$BUILD_PYTHONLESS" ]]; then
    if [[ -z "$WHEEL_FINAL_FOLDER" ]]; then
        package_dir='whl'
    else
        package_dir="$WHEEL_FINAL_FOLDER"
    fi
else
    package_dir='libtorch_packages'
fi

s3_dir="s3://pytorch/${package_dir}/${PIP_UPLOAD_FOLDER}cpu/"

# Upload the wheels to s3
# N.B. this is hardcoded to match wheel/build_wheel.sh, which copies built
# wheels to this folder
echo "Uploading all of: $(ls $package_dir) to $s3_dir"
ls "$package_dir" | xargs -I {} aws s3 cp "$package_dir"/{} "$s3_dir" --acl public-read
