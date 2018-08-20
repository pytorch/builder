#!/usr/bin/env bash

set -ex

if [[ -z "$PYTORCH_BUILD_VERSION" ]]; then
    export PYTORCH_BUILD_VERSION=0.4.1
fi
if [[ -z "$PYTORCH_BUILD_NUMBER" ]]; then
    export PYTORCH_BUILD_NUMBER=2
fi
export TH_BINARY_BUILD=1
export NO_CUDA=1
export CMAKE_LIBRARY_PATH="/opt/intel/lib:/lib:$CMAKE_LIBRARY_PATH"
export CMAKE_INCLUDE_PATH="/opt/intel:$CMAKE_INCLUDE_PATH"

# Keep an array of cmake variables to add to
if [[ -z "$CMAKE_ARGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build()
    CMAKE_ARGS=()
fi
if [[ -z "$EXTRA_CAFFE2_CMAKE_FLAGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build_caffe2()
    EXTRA_CAFFE2_CMAKE_FLAGS=()
fi

WHEELHOUSE_DIR="wheelhousecpu"

rm -rf /usr/local/cuda*

# Build for given Python versions, or for all in /opt/python if none given
if [[ -z "$DESIRED_PYTHON" ]]; then
    pushd /opt/python
    DESIRED_PYTHON=(*/)
    popd
fi
python_installations=()
for desired_py in "${DESIRED_PYTHON[@]}"; do
    python_installations+=("/opt/python/$desired_py")
    if [[ ! -d "/opt/python/$desired_py" ]]; then
        echo "Error: Given Python $desired_py is not in /opt/python"
        echo "All array elements of env variable DESIRED_PYTHON must be"
        echo "valid Python installations under /opt/python"
        exit 1
    fi
done
echo "Will build for all Pythons versions: ${DESIRED_PYTHON[@]}"

# ########################################################
# # Compile wheels
# #######################################################
# clone pytorch source code
PYTORCH_DIR="/pytorch"
if [[ ! -d "$PYTORCH_DIR" ]]; then
    git clone https://github.com/pytorch/pytorch $PYTORCH_DIR
    pushd $PYTORCH_DIR
    if ! git checkout v${PYTORCH_BUILD_VERSION}; then
       git checkout tags/v${PYTORCH_BUILD_VERSION}
    fi
else
    # the pytorch dir will already be cloned and checked-out on jenkins jobs
    pushd $PYTORCH_DIR
fi
git submodule update --init --recursive

OLD_PATH=$PATH
for PYDIR in "${python_installations[@]}"; do
    export PATH=$PYDIR/bin:$OLD_PATH
    python setup.py clean
    pip install -r requirements.txt
    if [[ $PYDIR  == "/opt/python/cp37-cp37m" ]]; then
	      pip install numpy==1.15
    else
	      pip install numpy==1.11
    fi
    time CMAKE_ARGS=${CMAKE_ARGS[@]} \
         EXTRA_CAFFE2_CMAKE_FLAGS=${EXTRA_CAFFE2_CMAKE_FLAGS[@]} \
         python setup.py bdist_wheel -d $WHEELHOUSE_DIR
done

popd

#######################################################################
# ADD DEPENDENCIES INTO THE WHEEL
# 
# auditwheel repair doesn't work correctly and is buggy
# so manually do the work of copying dependency libs and patchelfing
# and fixing RECORDS entries correctly
######################################################################
yum install -y zip openssl

fname_with_sha256() {
    HASH=$(sha256sum $1 | cut -c1-8)
    DIRNAME=$(dirname $1)
    BASENAME=$(basename $1)
    if [[ $BASENAME == "libnvrtc-builtins.so" ]]; then
	      echo $1
    else
	      INITNAME=$(echo $BASENAME | cut -f1 -d".")
	      ENDNAME=$(echo $BASENAME | cut -f 2- -d".")
	      echo "$DIRNAME/$INITNAME-$HASH.$ENDNAME"
    fi
}

make_wheel_record() {
    FPATH=$1
    if echo $FPATH | grep RECORD >/dev/null 2>&1; then
	# if the RECORD file, then
	echo "$FPATH,,"
    else
	HASH=$(openssl dgst -sha256 -binary $FPATH | openssl base64 | sed -e 's/+/-/g' | sed -e 's/\//_/g' | sed -e 's/=//g')
	FSIZE=$(ls -nl $FPATH | awk '{print $5}')
	echo "$FPATH,sha256=$HASH,$FSIZE"
    fi
}

DEPS_LIST=(
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libgomp.so.1"
)

mkdir -p /$WHEELHOUSE_DIR
cp $PYTORCH_DIR/$WHEELHOUSE_DIR/*.whl /$WHEELHOUSE_DIR
mkdir /tmp_dir
pushd /tmp_dir

for whl in /$WHEELHOUSE_DIR/torch*linux*.whl; do
    rm -rf tmp
    mkdir -p tmp
    cd tmp
    cp $whl .

    unzip -q $(basename $whl)
    rm -f $(basename $whl)
    
    # copy over needed dependent .so files over and tag them with their hash
    patched=()
    for filepath in "${DEPS_LIST[@]}"
    do
	filename=$(basename $filepath)
	destpath=torch/lib/$filename
	if [[ "$filepath" != "$destpath" ]]; then
	    cp $filepath $destpath
	fi

	patchedpath=$(fname_with_sha256 $destpath)
	patchedname=$(basename $patchedpath)
	if [[ "$destpath" != "$patchedpath" ]]; then
	    mv $destpath $patchedpath
	fi
	patched+=("$patchedname")
	echo "Copied $filepath to $patchedpath"
    done

    echo "patching to fix the so names to the hashed names"
    for ((i=0;i<${#DEPS_LIST[@]};++i));
    do
	find torch -name '*.so*' | while read sofile; do
	    origname=${DEPS_SONAME[i]}
	    patchedname=${patched[i]}
	    if [[ "$origname" != "$patchedname" ]]; then
		set +e
		patchelf --print-needed $sofile | grep $origname 2>&1 >/dev/null
		ERRCODE=$?
		set -e
		if [ "$ERRCODE" -eq "0" ]; then
		    echo "patching $sofile entry $origname to $patchedname"
		    patchelf --replace-needed $origname $patchedname $sofile
		fi
	    fi
	done
    done
    
    # set RPATH of _C.so and similar to $ORIGIN, $ORIGIN/lib
    find torch -maxdepth 1 -type f -name "*.so*" | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/lib'
	patchelf --set-rpath '$ORIGIN:$ORIGIN/lib' $sofile
	patchelf --print-rpath $sofile
    done
    
    # set RPATH of lib/ files to $ORIGIN
    find torch/lib -maxdepth 1 -type f -name "*.so*" | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN'
	patchelf --set-rpath '$ORIGIN' $sofile
	patchelf --print-rpath $sofile
    done


    # regenerate the RECORD file with new hashes 
    record_file=`echo $(basename $whl) | sed -e 's/-cp.*$/.dist-info\/RECORD/g'`
    echo "Generating new record file $record_file"
    rm -f $record_file
    # generate records for torch folder
    find torch -type f | while read fname; do
	echo $(make_wheel_record $fname) >>$record_file
    done
    # generate records for torch-[version]-dist-info folder
    find torch*dist-info -type f | while read fname; do
	echo $(make_wheel_record $fname) >>$record_file
    done

    # zip up the wheel back
    zip -rq $(basename $whl) torch*

    # replace original wheel
    rm -f $whl
    mv $(basename $whl) $whl
    cd ..
    rm -rf tmp
done

# Take the actual package name. Note how this always works because pip converts
# - to _ in names.
pushd /$WHEELHOUSE_DIR
built_wheels=(torch*.whl)
IFS='-' read -r package_name some_unused_variable <<< "${built_wheels[0]}"
echo "Expecting the built wheels to all be called '$package_name'"
popd

# Copy wheels to host machine for persistence after the docker
mkdir -p /remote/$WHEELHOUSE_DIR
cp /$WHEELHOUSE_DIR/torch*.whl /remote/$WHEELHOUSE_DIR/

# remove stuff before testing
rm -rf /opt/rh


# Test that all the wheels work
export OMP_NUM_THREADS=4 # on NUMA machines this takes too long
pushd $PYTORCH_DIR/test
for (( i=0; i<"${#DESIRED_PYTHON[@]}"; i++ )); do
    # This assumes that there is a 1:1 correspondence between python versions
    # and wheels, and that the python version is in the name of the wheel,
    # and that the python version matches the regex "cp\d\d-cp\d\dmu?"
    pydir="${python_installations[i]}"
    pyver="${DESIRED_PYTHON[i]}"
    pyver_short="${pyver:2:1}.${pyver:3:1}"

    # Install the wheel for this Python version
    "${PYDIR}/bin/pip" uninstall -y "$package_name"
    "${PYDIR}/bin/pip" install "$package_name" --no-index -f /$WHEELHOUSE_DIR --no-dependencies

    # Print info on the libraries installed in this wheel
    installed_libraries=($(find "$pydir/lib/python$pyver_short/site-packages/torch/" -name '*.so*'))
    echo "The wheel installed all of the libraries: ${installed_libraries[@]}"
    for installed_lib in "${installed_libraries[@]}"; do
        ldd "$installed_lib"
    done

    # Test that the wheel works
    LD_LIBRARY_PATH="/usr/local/nvidia/lib64" PYCMD=$PYDIR/bin/python $PYDIR/bin/python run_test.py
done
