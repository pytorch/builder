#!/bin/bash

set -ex
echo "build_multiple.sh at $(pwd) starting at $(date) on $(uname -a)"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Builds a set of packages sequentially with nice output and logging.
# De-duping is not done. If you specify something twice, it will get built twice.
#
# Command line arguments
#   DESIRED_PYTHONS
#     All Python versions to build for, separated by commas, in format '2.7mu'
#     for manywheels or in format '2.7' for conda/mac-wheels e.g.
#     '2.7m,2.7mu,3.5m,3.6m' or '2.7,3.7' . This can also just be the word
#     'all', which will expand to all supported python versions.
#
#   DESIRED_CUDAS
#     All CUDA versions to build for including 'cpu', separated by commas, in
#     format 'cpu' or 'cu92' or 'cu100' etc. e.g. 'cpu,cu92' or 'cu92,cu100'
#     . This can also just be the word 'all', which will expand to all
#     supported cpu/CUDA versions.

if [ "$#" -lt 3 ]; then
    echo 'Illegal number of parameters'
    echo '     build_multiple.sh [conda|manywheel|wheel] DESIRED_PYTHON,s DESIRED_CUDA,s'
    echo 'e.g. build_multiple.sh manywheel 2.7mu,3.5m,3.6m cpu,cu92'
    echo 'e.g. build_multiple.sh conda,manywheel 2.7 all'
    echo ' DESIRED_PYTHONs must match:   \d.\d(mu?)?'
    echo ' DESIRED_CUDAs must match  :   (cpu|cu\d\d)'
fi

nice_time () {
  echo "$(($1 / 60)) minutes and $(($1 % 60)) seconds"
}

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
      if [[ "$package_type" == 'conda' || "$package_type" == 'wheel' ]]; then
        all_pythons=('2.7' '3.5' '3.6' '3.7')
      else
        all_pythons=('2.7m' '2.7mu' '3.5m' '3.6m' '3.7m')
      fi
    fi
    if [[ "${all_cuda[0]}" == 'all' ]]; then
        all_cuda=('cpu' 'cu92' 'cu100' 'cu101')
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


set +x
echo
echo "$(date) :: Starting PyTorch binary build for $NIGHTLIES_DATE"
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

  # When the run build is running it will write logs to the logs/ folder. If
  # the build succeeds (as detected inside the docker image since exit codes
  # aren't being propogated), then the build will write 'SUCCESS' to its log in
  # logs/succeeded/ . When the build is over, we check if that file has been
  # written and if so move the log to logs/succeeded/ ; otherwise the build has
  # failed and logs are moved to logs/failed/
  log_name="${RUNNING_LOG_DIR}/${build_tag}.log"
  failed_log_loc="${FAILED_LOG_DIR}/${build_tag}.log"
  succeeded_log_loc="${SUCCEEDED_LOG_DIR}/${build_tag}.log"
  mkdir -p "$FAILED_LOG_DIR" || true
  mkdir -p "$SUCCEEDED_LOG_DIR" || true
  rm -f "$failed_log_loc"
  rm -f "$succeeded_log_loc"

  # Swap build script out on Macs
  if [[ "$(uname)" == 'Darwin' ]]; then
      build_script="${NIGHTLIES_BUILDER_ROOT}/cron/build_mac.sh"
  else
      build_script="${NIGHTLIES_BUILDER_ROOT}/cron/build_docker.sh"
  fi

  # Swap timeout out for libtorch
  if [[ "$package_type" == libtorch ]]; then
      _timeout="$PYTORCH_NIGHTLIES_LIBTORCH_TIMEOUT"
  else
      _timeout="$PYTORCH_NIGHTLIES_TIMEOUT"
  fi

  set +x
  echo
  echo "##############################"
  echo "$(date) :: Starting $package_type for py$py_ver and $cuda_ver"
  echo "Writing to log:  $log_name"

  set +e
  set -x
  SECONDS=0
  PACKAGE_TYPE="$package_type" \
      DESIRED_PYTHON="$py_ver" \
      DESIRED_CUDA="$cuda_ver" \
      ON_SUCCESS_WRITE_ME="$succeeded_log_loc" \
      $PORTABLE_TIMEOUT "$_timeout" \
          "$build_script" > "$log_name" 2>&1
  ret="$?"
  duration="$SECONDS"
  set -e

  # Keep track of the failed builds
  if [[ -f "$succeeded_log_loc" ]]; then
    set +x
    echo "$(date) :: Finished $build_tag in $(nice_time $duration)"
    echo "$(date) :: Status: SUCCESS!"
    rm -f "$succeeded_log_loc"
    mv "$log_name" "$succeeded_log_loc"
    good_builds+=("$build_tag")
  else
    set +x
    echo "$(date) :: Finished $build_tag in $(nice_time $duration)"
    echo "$(date) :: Status: FAILURE"
    >&2 echo "$(date) :: Status: FAILed building $build_tag"
    mv "$log_name" "$failed_log_loc"
    failed_builds+=("$build_tag")
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
