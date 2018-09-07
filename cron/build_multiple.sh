#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo 'Illegal number of parameters'
    echo '     build_multiple.sh [conda|manywheel] DESIRED_PYTHON,s DESIRED_CUDA,s'
    echo 'e.g. build_multiple.sh manywheel 2.7mu,3.5,3.6 cpu,cu80'
    echo 'e.g. build_multiple.sh conda,manywheel 2.7 all'
    echo ' DESIRED_PYTHONs must match:   \d.\d(mu?)?'
    echo ' DESIRED_CUDAs must match  :   (cpu|cu\d\d)'
fi

# Builds a set of packages sequentially with nice output and logging.
# De-duping is not done. If you specify something twice, it will get built twice.

nice_time () {
  echo "$(($1 / 3600 )) hours, $(($1 / 60)) minutes, and $(($1 % 60)) seconds"
}

set -ex

if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    echo "Env variable NIGHTLIES_FOLDER must be set"
    exit 1
fi
if [[ -z "$NIGHTLIES_DATE" ]]; then
    export NIGHTLIES_DATE="$(date +%Y_%m_%d)"
fi
today="$NIGHTLIES_FOLDER/$NIGHTLIES_DATE"
SOURCE_DIR=$(cd $(dirname $0) && pwd)

# Save all configurations into a big list and loop through them later
# Read through sets of <package types> <python versions> <cuda versions>
all_configs=()
while [[ $# -gt 0 ]]; do

  # Read the next configuration
  IFS=, all_packages=($1)
  shift
  IFS=, all_pythons=($1)
  shift
  IFS=, all_cuda=($1)

  # Expand 'all's and add all combos to the list of configurations
  for package_type in "${all_packages[@]}"; do
    if [[ "${all_pythons[0]}" == 'all' ]]; then
      if [[ "$package_type" == 'conda' ]]; then
        all_pythons=('2.7' '3.5' '3.6' '3.7')
      else
        all_pythons=('2.7m' '2.7mu' '3.5m' '3.6m' '3.7m')
      fi
    fi
    if [[ "${all_cuda[0]}" == 'all' ]]; then
        all_cuda=('cpu' 'cu80' 'cu90' 'cu92')
    fi
    for py_ver in "${all_pythons[@]}"; do
      for cuda_ver in "${all_cuda[@]}"; do
          all_configs+=("$package_type,$py_ver,$cuda_ver")
      done
    done
  done
  shift

  # Allow -- as harmless dividers for readability
  if [[ "$1" == '--' ]]; then
    shift
  fi
done

echo "ALL_PACKAGES IS $all_packages"
echo "ALL_PYTHONS IS $all_pythons"
echo "ALL_CUDA IS $all_cuda"


# Allow 'all' to translate to all python/cuda versions

set +x
echo
echo "Starting PyTorch binary build for $NIGHTLIES_DATE"
echo "$(date) :: Starting PyTorch binaries build"
echo "Building all of [${all_configs[@]}]"
set -x

# Build over all combinations
failed_builds=()
good_builds=()

for config in "${all_configs[@]}"; do
  IFS=, confs=($config)
  package_type="${confs[0]}"
  py_ver="${confs[1]}"
  cuda_ver="${confs[2]}"

  build_tag="${package_type}_${py_ver}_${cuda_ver}"
  log_name="${today}/logs/$build_tag.log"

  set +x
  echo
  echo "##############################"
  echo "$(date) :: Starting $package_type for py$py_ver and $cuda_ver"
  echo "Writing to log:  $log_name"

  set +e
  set -x
  if [[ -n "$VERBOSE" ]]; then
    SECONDS=0
    "$SOURCE_DIR/build.sh" "$package_type" "$py_ver" "$cuda_ver" 2>&1 | tee "$log_name"
    duration="$SECONDS"
  else
    SECONDS=0
    "$SOURCE_DIR/build.sh" "$package_type" "$py_ver" "$cuda_ver" > "$log_name" 2>&1
    duration="$SECONDS"
  fi
  ret="$?"
  set -e

  # Keep track of the failed builds
  if [[ "$ret" != 0 ]]; then
    set +x
    echo "$(date) :: Finished $build_tag in $(nice_time $duration)"
    echo "$(date) :: Status: FAILURE"
    >&2 echo "$(date) :: Status: FAILed building $build_tag"
    echo "$build_tag" >> "${today}/logs/failed"
    failed_builds+=("$build_tag")
  else
    set +x
    echo "$(date) :: Finished $build_tag in $(nice_time $duration)"
    echo "$(date) :: Status: SUCCESS!"
    good_builds+=("$build_tag")
  fi

  echo "################################################################################"
  set -x
done

set +x
echo "$(date) :: All builds finished."
echo "Final status:"
echo "  Failed  : ${#failed_builds[@]}"
for build in "${failed_builds[@]}"; do
    IFS=_ params=("$build")
    echo "     ${params[0]} ${params[1]} ${params[2]}"
done
echo "  Success : ${#good_builds[@]}"
for build in "${good_builds[@]}"; do
    IFS=_ params=("$build")
    echo "     ${params[0]} ${params[1]} ${params[2]}"
done
