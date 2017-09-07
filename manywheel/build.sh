export PYTORCH_BUILD_VERSION=0.2.0
export PYTORCH_BUILD_NUMBER=3
export PYTORCH_BINARY_BUILD=1
export TH_BINARY_BUILD=1

CUDA_VERSION=$(nvcc --version|tail -n1|cut -f5 -d" "|cut -f1 -d",")

export TORCH_CUDA_ARCH_LIST="3.0;3.5;5.0;5.2+PTX"
if [[ $CUDA_VERSION == "8.0" ]]; then
    echo "CUDA 8.0 Detected"
    export TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST;6.0;6.1"
fi
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
echo $TORCH_CUDA_ARCH_LIST
export CMAKE_LIBRARY_PATH="/opt/intel/lib:/lib:$CMAKE_LIBRARY_PATH"

if [[ $CUDA_VERSION == "8.0" ]]; then
    WHEELHOUSE_DIR="wheelhouse"
else
    WHEELHOUSE_DIR="wheelhouse75"
fi

# clone pytorch source code
git clone https://github.com/pytorch/pytorch -b v${PYTORCH_BUILD_VERSION}
cd pytorch

OLD_PATH=$PATH
# Compile wheels
for PYDIR in /opt/python/*; do
    export PATH=$PYDIR/bin:$OLD_PATH
    python setup.py clean
    pip install -r requirements.txt
    pip install numpy
    time python setup.py bdist_wheel -d $WHEELHOUSE_DIR
done

/opt/python/cp36-cp36m/bin/pip install auditwheel
yum install -y zip

for whl in $WHEELHOUSE_DIR/torch*.whl; do
    /opt/python/cp36-cp36m/bin/auditwheel repair $whl -w /$WHEELHOUSE_DIR/ -L lib
done

for whl in /$WHEELHOUSE_DIR/torch*manylinux*.whl; do
    # auditwheel repair is not enough
    # TH, THNN, THC, THCUNN need some manual work too, as they are not
    # touched by auditwheel
    mkdir tmp
    cd tmp
    cp $whl .
    unzip $(basename $whl)
    rm -f $(basename $whl)

    # libTH
    patchelf --set-rpath '$ORIGIN' torch/lib/libTH.so.1
    patchelf --replace-needed libgomp.so.1 libgomp-ae56ecdc.so.1.0.0 torch/lib/libTH.so.1

    # libTHNN
    patchelf --set-rpath '$ORIGIN' torch/lib/libTHNN.so.1
    patchelf --replace-needed libgomp.so.1       libgomp-ae56ecdc.so.1.0.0      torch/lib/libTHNN.so.1

    # libTHC
    patchelf --set-rpath '$ORIGIN' torch/lib/libTHC.so.1
    patchelf --replace-needed libgomp.so.1       libgomp-ae56ecdc.so.1.0.0      torch/lib/libTHC.so.1
    if [[ $CUDA_VERSION == "8.0" ]]; then
	patchelf --replace-needed libcudart.so.8.0   libcudart-5d6d23a3.so.8.0.61   torch/lib/libTHC.so.1
	patchelf --replace-needed libcublas.so.8.0   libcublas-e78c880d.so.8.0.88   torch/lib/libTHC.so.1
	patchelf --replace-needed libcusparse.so.8.0 libcusparse-94011b8d.so.8.0.61 torch/lib/libTHC.so.1
	patchelf --replace-needed libcurand.so.8.0   libcurand-3d68c345.so.8.0.61   torch/lib/libTHC.so.1
    else
	patchelf --replace-needed libcudart.so.7.5   libcudart-e0aa9238.so.7.5.18   torch/lib/libTHC.so.1
	patchelf --replace-needed libcublas.so.7.5   libcublas-74156a04.so.7.5.18   torch/lib/libTHC.so.1
	patchelf --replace-needed libcusparse.so.7.5 libcusparse-652fe42d.so.7.5.18 torch/lib/libTHC.so.1
	patchelf --replace-needed libcurand.so.7.5   libcurand-5c46e900.so.7.5.18   torch/lib/libTHC.so.1
    fi

    # libTHCUNN
    patchelf --set-rpath '$ORIGIN' torch/lib/libTHCUNN.so.1
    if [[ $CUDA_VERSION == "8.0" ]]; then
	patchelf --replace-needed libcudart.so.8.0   libcudart-5d6d23a3.so.8.0.61   torch/lib/libTHCUNN.so.1
	patchelf --replace-needed libcusparse.so.8.0 libcusparse-94011b8d.so.8.0.61 torch/lib/libTHCUNN.so.1
    else
	patchelf --replace-needed libcudart.so.7.5   libcudart-e0aa9238.so.7.5.18   torch/lib/libTHCUNN.so.1
	patchelf --replace-needed libcusparse.so.7.5 libcusparse-652fe42d.so.7.5.18 torch/lib/libTHCUNN.so.1
    fi

    # libTHS
    patchelf --set-rpath '$ORIGIN' torch/lib/libTHS.so.1

    # libTHCS
    patchelf --set-rpath '$ORIGIN' torch/lib/libTHCS.so.1
    if [[ $CUDA_VERSION == "8.0" ]]; then
	patchelf --replace-needed libcudart.so.8.0   libcudart-5d6d23a3.so.8.0.61   torch/lib/libTHCS.so.1
	patchelf --replace-needed libcublas.so.8.0   libcublas-e78c880d.so.8.0.88   torch/lib/libTHCS.so.1
	patchelf --replace-needed libcusparse.so.8.0 libcusparse-94011b8d.so.8.0.61 torch/lib/libTHCS.so.1
    else
	patchelf --replace-needed libcudart.so.7.5   libcudart-e0aa9238.so.7.5.18   torch/lib/libTHCS.so.1
	patchelf --replace-needed libcublas.so.7.5   libcublas-74156a04.so.7.5.18   torch/lib/libTHCS.so.1
	patchelf --replace-needed libcusparse.so.7.5 libcusparse-652fe42d.so.7.5.18 torch/lib/libTHCS.so.1
    fi

    # libTHPP
    patchelf --set-rpath '$ORIGIN' torch/lib/libTHPP.so.1
    if [[ $CUDA_VERSION == "8.0" ]]; then
	patchelf --replace-needed libcudart.so.8.0   libcudart-5d6d23a3.so.8.0.61   torch/lib/libTHPP.so.1
    else
	patchelf --replace-needed libcudart.so.7.5   libcudart-e0aa9238.so.7.5.18   torch/lib/libTHPP.so.1
    fi

    # libTHD
    patchelf --set-rpath '$ORIGIN' torch/lib/libTHD.so.1

    # libATen
    patchelf --set-rpath '$ORIGIN' torch/lib/libATen.so.1
    if [[ $CUDA_VERSION == "8.0" ]]; then
	patchelf --replace-needed libcudart.so.8.0   libcudart-5d6d23a3.so.8.0.61   torch/lib/libATen.so.1
    else
	patchelf --replace-needed libcudart.so.7.5   libcudart-e0aa9238.so.7.5.18   torch/lib/libATen.so.1
    fi
    
    # libnccl
    patchelf --set-rpath '$ORIGIN' torch/lib/libnccl.so.1
    if [[ $CUDA_VERSION == "8.0" ]]; then
	patchelf --replace-needed libcudart.so.8.0   libcudart-5d6d23a3.so.8.0.61   torch/lib/libnccl.so.1
    else
	patchelf --replace-needed libcudart.so.7.5   libcudart-e0aa9238.so.7.5.18   torch/lib/libnccl.so.1
    fi
    rm torch/lib/libnccl.so

    # libshm
    patchelf --set-rpath '$ORIGIN' torch/lib/libshm.so

    # regenerate the RECORD file with new hashes 
    record_file=`echo $(basename $whl) | sed -e 's/-cp.*$/.dist-info\/RECORD/g'`
    echo "$record_file found. modifying"
    new_record_file="$record_file"_new
    while read -r line
    do
      record_item="$line"
      IFS=, read -r filename digestcombined size <<< "$record_item"
      IFS== read -r digestmethod digest <<< "$digestcombined"

      if [ $filename == $record_file ]
      then
        echo "$line" >> $new_record_file
      else
        new_digest=`openssl dgst -sha256 -binary $filename | openssl base64 | sed -e 's/+/-/g' | sed -e 's/\//_/g' | sed -e 's/=//g'`
        new_size=`ls -nl $filename | awk '{print $5}'`
        echo $filename,$digestmethod=$new_digest,$new_size >> $new_record_file
      fi
    done < "$record_file"
    mv $new_record_file $record_file

    # zip up the wheel back
    zip -r $(basename $whl) torch*

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
pushd /pytorch/test
for PYDIR in /opt/python/*; do
    "${PYDIR}/bin/pip" uninstall -y torch
    "${PYDIR}/bin/pip" install torch --no-index -f /$WHEELHOUSE_DIR
    LD_LIBRARY_PATH="" PYCMD=$PYDIR/bin/python ./run_test.sh
done
