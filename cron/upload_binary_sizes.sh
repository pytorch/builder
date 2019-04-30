#!/bin/bash

# The hud at pytorch.org/builder populates its binary sizes from reading json
# files at s3://pytorch/nightly_logs/binary_sizes/cpu/2019_01_01.json (for all
# cpu versions and dates). This script populates those files by parsing conda
# info output or from s3
# Usage:
#   collect_binary_sizes.sh [date pytorch_version_preamble
#
# This script needs a date to search for, and it also needs the full version
# string for that date so it can query `conda search`. You need to either
# 1. source builder_root/cron/nightly_defaults.sh first or
# 2. Pass in the date and the version preamble. This script assumes that the
#    version string follows 1.1.0.dev20190101 format; the version preamble is
#    the '1.1.0.dev' part. The date should be given is 2019_01_01 format.
#
# N.B. this assumes that there is one version for each date. If you upload
#      1.1.0 *and* 1.2.0 binaries on the same date, then this will probably
#      silently intermix the binary sizes.
# N.B. cuda versions are hardcoded into this file in the s3 section.
#
# If you look closely you'll notice that uploaded json files have underscores
# in their names like 2019_01_01 but the versions use 20190101. This is because
# we want the jsons to be more human readable, but need the version dates to
# match what `conda search` knows about

set -ex
echo "collect_binary_sizes.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
# N.B. we do not source nightly_defaults.sh to avoid cloning repos every date
# of a backfill

# Optionally accept a date to upload for
if [[ "$#" > 0 ]]; then
    if [[ "$#" == 1 ]]; then
      echo "You must specify the version preamble too"
      exit 1
    fi
    target_date="$1"
    version_preamble="$2"

    # The docs say that this takes an underscore date but people don't read
    # docs, so if it's wrong then we fix it.
    if [[ "${#target_date}" == 8 ]]; then
      target_date="${target_date:0:4}_${target_date:4:2}_${target_date:6:2}"
    fi
    target_date="$(echo $target_date | tr '-' '_')"
    target_version="${version_preamble}$(echo $target_date | tr -d _)"
else
    source "${SOURCE_DIR}/nightly_defaults.sh"
    target_date="$NIGHTLIES_DATE"
    target_version="$PYTORCH_BUILD_VERSION"
fi

# First write lines of "$platform $pkg_type $py_ver $cu_ver $size" to a log,
# then parse that into json at the end
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
# Collect wheel binary sizes. These are read from s3
cuda_versions=("cpu" "cu90" "cu100")
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
# N.B. if you want to change the name of this json file then you have to
# coordinate the change with the gh-pages-src branch
aws s3 cp "$binary_sizes_json" "s3://pytorch/nightly_logs/binary_sizes/" --acl public-read --quiet
