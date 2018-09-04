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

set -e

today="/scratch/nightlies/$(date +%Y_%m_%d)"
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
successful_builds=()
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
      log_name="${today}/logs/${package_type}_${py_ver}_${cuda_ver}"
      set +x
      echo
      echo "$(date) :: Starting $package_type for py$py_ver and $cuda_ver"
      echo "Writing to log:  $log_name"
  
      set +e
      set -x
      if [[ -n "$VERBOSE" ]]; then
        "$SOURCE_DIR/build.sh" "$package_type" "$py_ver" "$cuda_ver" 2>&1 | tee "$log_name"
      else
        "$SOURCE_DIR/build.sh" "$package_type" "$py_ver" "$cuda_ver" > "$log_name" 2>&1
      fi
      ret="$?"
      set -e
  
      # Keep track of the failed builds
      if [[ "$ret" != 0 ]]; then
        echo "$(date) :: Build status of $package_type for py$py_ver and $cuda_ver :: FAILURE!"
        echo "$1_$2_$3" >> "$package_type $py_ver $cuda_ver"
        failed_builds+=("$package_type,$py_ver,$cuda_ver")
      else
        echo "$(date) :: Build status of $package_type for py$py_ver and $cuda_ver :: SUCCESS!"
        successful_builds+=("$package_type,$py_ver,$cuda_ver")
      fi
    done
  done
done

set +x
echo "$(date) :: All builds finished."
echo "Final status:"
echo "  Failed  : ${#failed_builds[@]}"
for build in "${failed_builds[@]}"; do
    IFS=, params=("$build")
    echo "     ${params[0]} ${params[1]} ${params[2]}"
done
echo "  Success : ${#successful_builds[@]}"
for build in "${failed_builds[@]}"; do
    IFS=, params=("$build")
    echo "     ${params[0]} ${params[1]} ${params[2]}"
done
