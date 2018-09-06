#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo 'Illegal number of parameters'
    echo '     build_cross.sh [conda|manywheel] DESIRED_PYTHON,s DESIRED_CUDA,s'
    echo 'e.g. build_cross.sh manywheel 2.7mu,3.5,3.6 cpu,cu80'
    echo 'e.g. build_cross.sh conda,manywheel 2.7 all'
    echo ' DESIRED_PYTHONs must match:   \d.\d(mu?)?'
    echo ' DESIRED_CUDAs must match  :   (cpu|cu\d\d)'
    exit 1
fi

nice_time () {
  echo "$(($1 / 3600 )) hours, $(($1 / 60)) minutes, and $(($1 % 60)) seconds"
}

set -ex

if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    NIGHTLIES_FOLDER='/scratch/hellemn/nightlies/'
fi
today="$NIGHTLIES_FOLDER/$(date +%Y_%m_%d)"
SOURCE_DIR=$(cd $(dirname $0) && pwd)

IFS=, all_packages=($1)
IFS=, all_pythons=($2)
IFS=, all_cuda=($3)

# Allow 'all' to translate to all python/cuda versions
if [[ "${all_cuda[0]}" == 'all' ]]; then
    all_cuda=('cpu' 'cu80' 'cu90' 'cu92')
fi

set +x
echo
echo 'Starting PyTorch binary build.'
echo "$(date) :: Starting PyTorch binaries build"
echo "Building [${all_packages[@]}] x [${all_cuda[@]}] x [${all_pythons[@]}]"
set -x

# Build over all combinations
failed_builds=()
good_builds=()
for package_type in "${all_packages[@]}"; do

  # Allow 'all' to translate to all python/cuda versions
  if [[ "${all_pythons[0]}" == 'all' ]]; then
    if [[ "$package_type" == 'conda' ]]; then
      all_pythons=('2.7' '3.5' '3.6' '3.7')
    else
      all_pythons=('2.7m' '2.7mu' '3.5m' '3.6m' '3.7m')
    fi
  fi

  # Loop through all Python/CUDA versions sequentially
  for py_ver in "${all_pythons[@]}"; do
    for cuda_ver in "${all_cuda[@]}"; do
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
        echo "$(date) :: Build status of $package_type for py$py_ver and $cuda_ver :: SUCCESS!"
        good_builds+=("$build_tag")
      fi

      echo "################################################################################"
    done
  done
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
