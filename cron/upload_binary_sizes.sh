#!/bin/bash

set -ex
echo "collect_binary_sizes.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
# N.B. we do not source nightly_defaults.sh to avoid cloning repos every date
# of a backfill

# Usage:
#   collect_binary_sizes.sh [date]
# Queries s3 and conda to get the binary sizes (as they're stored in the cloud)
# for a day

# Optionally accept a date to upload for
if [[ "$#" > 0 ]]; then
    target_date=$1
    target_version="1.0.0.dev$(echo $target_date | tr -d _)"
else
    source "${SOURCE_DIR}/nightly_defaults.sh"
    target_date="$NIGHTLIES_DATE"
    target_version="$PYTORCH_BUILD_VERSION"
fi

binary_sizes_log="$SOURCE_DIR/binary_sizes.log"
binary_sizes_json="$SOURCE_DIR/$target_date.json"
rm -f "$binary_sizes_log"
rm -f "$binary_sizes_json"
touch "$binary_sizes_log"


##############################################################################
# Collect conda binary sizes
# This is read from `conda search`. 
conda_platforms=('linux-64' 'osx-64')
conda_pkg_names=('pytorch-nightly' 'pytorch-nightly-cpu')
tmp_json="_conda_search.json"
for pkg_name in "${conda_pkg_names[@]}"; do
    for platform in "${conda_platforms[@]}"; do

        # Read the info from conda-search
        touch "$tmp_json"
        set +e
        conda search -c pytorch --json --platform "$platform" \
                "$pkg_name==$target_version" > "$tmp_json"
        if [[ "$?" != 0 ]]; then
            set -e
            echo "ERROR: Could not query conda for $platform"
            continue
        fi
        set -e

        # Call Python to parse the json into 'log_name_form size_in_bytes'
        python "$SOURCE_DIR/parse_conda_json.py" "$tmp_json" "$binary_sizes_log"
    done
done
rm -f "$tmp_json"


##############################################################################
# Collect wheel binary sizes
cuda_versions=("cpu" "cu80" "cu90" "cu92")
for cu_ver in "${cuda_versions[@]}"; do

    # Read the info from s3
    s3_dir="s3://pytorch/whl/nightly/${cu_ver}/"
    set +e
    outputs=($(aws s3 ls "$s3_dir" | grep --only-matching "\S* \S*$target_version\S*\.whl"))
    if [[ "$?" != 0 ]]; then
        set -e
        echo "ERROR: Could find no [many]wheels for $cu_ver"
        continue
    fi
    set -e

    # outputs is now a list of [size whl size whl...] as different elements
    for i in $(seq 0 2 $(( ${#outputs[@]} - 1 )) ); do
        whl="${outputs[$(( $i + 1 ))]}"
        size="${outputs[$i]}"

        # Parse the python version from the whl name. If the name is in format
        # torch_nightly-1.0.0.dev20181113-cp35-cp35m-linux_x86_64.whl then it's
        # linux, otherwise it should have a '-none' in the name and be for mac
        if [[ "$whl" == *none* ]]; then
            platform='macos'
            pkg_type='wheel'
            # The regex matches -cp27-none- , there is no 'mu' variant for mac
            py_ver="$(echo $whl | grep --only-matching '\-cp..\-none\-')"
            py_ver="${py_ver:3:1}.${py_ver:4:1}"
        else
            platform='linux'
            pkg_type='manywheel'
            # The regex matches -cp27-cp27mu or -cp27-cp27m
            py_ver="$(echo $whl | grep --only-matching '\-cp..\-cp..mu\?')"
            py_ver="${py_ver:8:1}.${py_ver:9}"
        fi

        # Write to binary_sizes_log in log_name_form
        echo "$platform $pkg_type $py_ver $cu_ver $size" >> "$binary_sizes_log"
    done
done

# Convert the file of '<platform> <log_name> <size>' into a json for easy
# ingestion in the react HUD
python "$SOURCE_DIR/write_json.py" "$binary_sizes_log" "$binary_sizes_json"

# Upload the log to s3
aws s3 cp "$binary_sizes_json" "s3://pytorch/nightly_logs/binary_sizes/" --acl public-read --quiet
