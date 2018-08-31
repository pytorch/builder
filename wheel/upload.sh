set -ex

# N.B. this is hardcoded to cpu, as at the time of writing Mac builds are cpu
# only

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)

s3_dir="s3://pytorch/whl/${PIP_UPLOAD_FOLDER}cpu/"
wheel_dir='whl'

# Upload the wheels to s3
# N.B. this is hardcoded to match wheel/build_wheel.sh, which copies built
# wheels to this folder
echo "Uploading all of: $(ls $wheel_dir) to $s3_dir"
ls "$wheel_dir" | xargs -I {} aws s3 cp "$wheel_dir"/{} "$s3_dir" --acl public-read
