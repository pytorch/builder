#!/bin/bash
set -ex

# This script is used to backfill binary sizes (backfill the .json files stored
# at s3://pytorch/nightly_logs/binary_sizes/). All it does it call
# upload_binary_sizes.sh for a range of dates. This script should not be called
# often, so the ranges of the dates are hardcoded in.

# The upload_binary_sizes.sh script expects dates with underscores in
# 2019_01_01 format.
# You should make sure that end date is actually after start date, and that
# both are in underscore format
START_DATE="2019_08_03"
END_DATE="$(date +%Y_%m_%d)"

# The upload_binary_sizes script needs to construct the entire Pytorch binary
# versions in order to query conda for the sizes. There is a built-in
# assumption in many places that the version is like 1.1.0.dev20190101.
# N.B. this means you cannot use this script across a version boundary, as the
# script will only work for part of the range
CURRENT_PYTORCH_VERSION_PREAMBLE="1.2.0.dev"

# TODO actually compare times instead of string comparisons. It's easy to get
# an infinite loop this way.
current_date="$START_DATE"
while [ "$current_date" != "$END_DATE" ]; do
  ./upload_binary_sizes.sh "$current_date" "$CURRENT_PYTORCH_VERSION_PREAMBLE"

  # The date command understands 20190101 and 2019-01-01 but not 2019_01_01
  # without work, so we just remove the '_' in the calculation
  current_date="$(date +%Y_%m_%d -d "$(echo $current_date | tr -d '_') + 1 day")"
done
