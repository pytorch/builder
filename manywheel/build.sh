#!/usr/bin/env bash

export PYTORCH_BUILD_VERSION=0.3.0
export PYTORCH_BUILD_NUMBER=4
export PYTORCH_BINARY_BUILD=1
export TH_BINARY_BUILD=1
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export CMAKE_LIBRARY_PATH="/opt/intel/lib:/lib:$CMAKE_LIBRARY_PATH"

CUDA_VERSION=$(nvcc --version|tail -n1|cut -f5 -d" "|cut -f1 -d",")

export TORCH_CUDA_ARCH_LIST="3.0;3.5;5.0;5.2+PTX"
if [[ $CUDA_VERSION == "8.0" ]]; then
    echo "CUDA 8.0 Detected"
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1"
elif [[ $CUDA_VERSION == "9.0" ]]; then
    echo "CUDA 9.0 Detected"
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1;7.0"
fi
# export TORCH_CUDA_ARCH_LIST="6.0" # TODO: remove
echo $TORCH_CUDA_ARCH_LIST

if [[ $CUDA_VERSION == "8.0" ]]; then
    WHEELHOUSE_DIR="wheelhouse80"
elif [[ $CUDA_VERSION == "9.0" ]]; then
    WHEELHOUSE_DIR="wheelhouse90"
else
    WHEELHOUSE_DIR="wheelhouse75"
fi

rm -rf /opt/python/cpython-2.6.9-ucs2  /opt/python/cpython-2.6.9-ucs4
# rm -rf /opt/python/cp35*  # TODO: remove
# rm -rf /opt/python/cp27*  # TODO: remove
ls /opt/python

# ########################################################
# # Compile wheels
# #######################################################
# clone pytorch source code
git clone --recursive https://github.com/pytorch/pytorch -b v${PYTORCH_BUILD_VERSION}

pushd pytorch

OLD_PATH=$PATH
for PYDIR in /opt/python/*; do
    export PATH=$PYDIR/bin:$OLD_PATH
    python setup.py clean
    pip install -r requirements.txt
    pip install numpy==1.11
    time python setup.py bdist_wheel -d $WHEELHOUSE_DIR
done

popd

#######################################################################
# ADD DEPENDENCIES INTO THE WHEEL
# 
# auditwheel repair doesn't work correctly and is buggy
# so manually do the work of copying dependency libs and patchelfing
# and fixing RECORDS entries correctly
######################################################################
yum install -y zip

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

if [[ $CUDA_VERSION == "7.5" ]]; then
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.7.5.18"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libcublas.so.7.5.18"
    "/usr/local/cuda/lib64/libcurand.so.7.5.18"
    "/usr/local/cuda/lib64/libcusparse.so.7.5.18"
    "/usr/local/cuda/lib64/libnvrtc.so.7.5.17"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/local/cuda/lib64/libcudnn.so.6.0.21"
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libcudart.so.7.5"
    "libnvToolsExt.so.1"
    "libcublas.so.7.5"
    "libcurand.so.7.5"
    "libcusparse.so.7.5"
    "libnvrtc.so.7.5"
    "libnvrtc-builtins.so"
    "libcudnn.so.6"
    "libgomp.so.1"
)

elif [[ $CUDA_VERSION == "8.0" ]]; then
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.8.0.61"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libcublas.so.8.0.88"
    "/usr/local/cuda/lib64/libcurand.so.8.0.61"
    "/usr/local/cuda/lib64/libcusparse.so.8.0.61"
    "/usr/local/cuda/lib64/libnvrtc.so.8.0.61"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/local/cuda/lib64/libcudnn.so.7.0.3"
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libcudart.so.8.0"
    "libnvToolsExt.so.1"
    "libcublas.so.8.0"
    "libcurand.so.8.0"
    "libcusparse.so.8.0"
    "libnvrtc.so.8.0"
    "libnvrtc-builtins.so"
    "libcudnn.so.7"
    "libgomp.so.1"
)

elif [[ $CUDA_VERSION == "9.0" ]]; then
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.9.0"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libcublas.so.9.0"
    "/usr/local/cuda/lib64/libcurand.so.9.0"
    "/usr/local/cuda/lib64/libcusparse.so.9.0"
    "/usr/local/cuda/lib64/libnvrtc.so.9.0"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/local/cuda/lib64/libcudnn.so.7"
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libcudart.so.9.0"
    "libnvToolsExt.so.1"
    "libcublas.so.9.0"
    "libcurand.so.9.0"
    "libcusparse.so.9.0"
    "libnvrtc.so.9.0"
    "libnvrtc-builtins.so"
    "libcudnn.so.7"
    "libgomp.so.1"
)
else
    echo "Unknown cuda version $CUDA_VERSION"
    exit 1
fi

mkdir -p /$WHEELHOUSE_DIR
cp pytorch/$WHEELHOUSE_DIR/*.whl /$WHEELHOUSE_DIR

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
	cp $filepath $destpath
	
	if [[ $CUDA_VERSION == "9.0" ]]; then
	    echo "Copied $filepath to $destpath"
	else
	    patchedpath=$(fname_with_sha256 $destpath)
	    patchedname=$(basename $patchedpath)
	    mv $destpath $patchedpath
	    patched+=("$patchedname")
	    echo "Copied $filepath to $patchedpath"
	fi
    done

    if [[ $CUDA_VERSION != "9.0" ]]; then
	echo "patching to fix the so names to the hashed names"
	for ((i=0;i<${#DEPS_LIST[@]};++i));
	do
	    find torch -name '*.so*' | while read sofile; do
		origname=${DEPS_SONAME[i]}
		patchedname=${patched[i]}
		set +e
		patchelf --print-needed $sofile | grep $origname 2>&1 >/dev/null
		ERRCODE=$?
		set -e
		if [ "$ERRCODE" -eq "0" ]; then
		    echo "patching $sofile entry $origname to $patchedname"
		    patchelf --replace-needed $origname $patchedname $sofile
		fi
	    done
	done
    fi
    
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


    # remove the symlink and just keep libnccl.so.1
    rm -f torch/lib/libnccl.so

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

mkdir -p /remote/$WHEELHOUSE_DIR
cp /$WHEELHOUSE_DIR/torch*.whl /remote/$WHEELHOUSE_DIR/

# remove stuff before testing
rm -rf /usr/local/cuda*
rm -rf /opt/rh

export OMP_NUM_THREADS=4 # on NUMA machines this takes too long
pushd /pytorch/test
for PYDIR in /opt/python/*; do
    "${PYDIR}/bin/pip" uninstall -y torch
    "${PYDIR}/bin/pip" install torch --no-index -f /$WHEELHOUSE_DIR
    LD_LIBRARY_PATH="/usr/local/nvidia/lib64" PYCMD=$PYDIR/bin/python ./run_test.sh
done
