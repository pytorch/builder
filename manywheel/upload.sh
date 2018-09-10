set -ex

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)

# Upload for all CUDA/cpu versions if not given one to use
if [[ -z "$CUDA_VERSIONS" ]]; then
    CUDA_VERSIONS=('cpu' 'cu80' 'cu90' 'cu92')
fi

# Make sure the user specifically refers to an upload folder
if [[ -z "$PIP_UPLOAD_FOLDER" ]]; then
    echo 'The upload folder is not set. We refuse to upload.'
    echo 'Please set PIP_UPLOAD_FOLDER'
    exit 1
fi

for cuda_ver in "${CUDA_VERSIONS[@]}"; do
    s3_wheel_dir="s3://pytorch/whl/${PIP_UPLOAD_FOLDER}${cuda_ver}/"
    s3_libtorch_dir="s3://pytorch/libtorch/${PIP_UPLOAD_FOLDER}${cuda_ver}/"
    if [[ "$cuda_ver" == cpu ]]; then
        wheel_dir="wheelhousecpu/"
        libtorch_dir="libtorch_housecpu/"
    else
        wheel_dir="wheelhouse${cuda_ver:2:2}/"
        libtorch_dir="libtorch_house${cuda_ver:2:2}/"
    fi

    # Upload the wheels to s3
    echo "Uploading all of: $(ls $wheel_dir) to $s3_wheel_dir"
    ls "$wheel_dir" | xargs -I {} aws s3 cp "$wheel_dir"/{} "$s3_wheel_dir" --acl public-read

    echo "Uploading all of: $(ls $libtorch_dir) to $s3_libtorch_dir"
    ls "$libtorch_dir" | xargs -I {} aws s3 cp "$libtorch_dir"/{} "$s3_libtorch_dir" --acl public-read
done
