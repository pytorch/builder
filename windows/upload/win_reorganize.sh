set -ex

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters. Pass pytorch or torchvision as the option"
    exit 1
fi

package_name=$1

if [[ "$package_name" == pytorch ]]; then
    echo "Reorganizing pytorch binaries"
elif [[ "$package_name" == torchvision ]]; then
    echo "Reorganizing torchvision binaries"
else
    echo "Unknown option $package_name"
    exit 1
fi

# the branch names that get published are:
# remotes/origin/conda_3.5
# remotes/origin/conda_3.5_cuda101
# remotes/origin/conda_3.5_cuda92
# remotes/origin/conda_3.6
# remotes/origin/conda_3.6_cuda101
# remotes/origin/conda_3.6_cuda92
# remotes/origin/conda_3.7
# remotes/origin/conda_3.7_cuda101
# remotes/origin/conda_3.7_cuda92
# remotes/origin/master
# remotes/origin/wheels_3
# remotes/origin/wheels_3_debug
# remotes/origin/wheels_3.5
# remotes/origin/wheels_3.5_cuda101
# remotes/origin/wheels_3.5_cuda92
# remotes/origin/wheels_3.6
# remotes/origin/wheels_3.6_cuda101
# remotes/origin/wheels_3.6_cuda92
# remotes/origin/wheels_3.7
# remotes/origin/wheels_3.7_cuda101
# remotes/origin/wheels_3.7_cuda92
# remotes/origin/wheels_3_cuda101
# remotes/origin/wheels_3_cuda101_debug
# remotes/origin/wheels_3_cuda92
# remotes/origin/wheels_3_cuda92_debug


PYTHON_VERSIONS=('3.5' '3.6' '3.7')
DTYPE=('conda' 'wheels')

CUDA_VERSIONS=('' '_cuda92' '_cuda101')
CUDA_FOLDERS=('cpu' 'cuda92' 'cuda101')
CUDA_VERSIONS_FINAL=('cpu' 'cu92' 'cu101')

mkdir winwheels || true
final_dir="$(pwd)/winwheels"

pushd pytorch_builder
for ((i=0;i<${#CUDA_VERSIONS[@]};++i)); do
    CUDA_VERSION=${CUDA_VERSIONS[i]}
    CUDA_VERSION_FINAL=${CUDA_VERSIONS_FINAL[i]}
    CUDA_FOLDER=${CUDA_FOLDERS[i]}
    for py_ver in "${PYTHON_VERSIONS[@]}"; do
	for dtype in "${DTYPE[@]}"; do

	    BRANCH_NAME=remotes/origin/${dtype}_$py_ver$CUDA_VERSION
	    VISION_BRANCH_NAME=remotes/origin/vision_${dtype}_$py_ver$CUDA_VERSION
	    if [[ "$package_name" == pytorch ]]; then
		echo $BRANCH_NAME
		git checkout $BRANCH_NAME
		if [[ "$dtype" == "wheels"* ]]; then
	    	    mkdir -p $final_dir/whl/$CUDA_VERSION_FINAL
	    	    cp $dtype/$CUDA_FOLDER/* $final_dir/whl/$CUDA_VERSION_FINAL/
		else
	    	    mkdir -p $final_dir/conda
	    	    cp $dtype/* $final_dir/conda/
		fi
	    elif [[ "$package_name" == torchvision ]]; then
		echo $VISION_BRANCH_NAME
		git checkout $VISION_BRANCH_NAME
		if [[ "$dtype" == "wheels"* ]]; then
	    	    mkdir -p $final_dir/whl/$CUDA_VERSION_FINAL
	    	    cp vision_$dtype/$CUDA_FOLDER/* $final_dir/whl/$CUDA_VERSION_FINAL/
		else
	    	    mkdir -p $final_dir/conda
	    	    cp vision_$dtype/* $final_dir/conda/
		fi
	    fi
	done
    done
done
popd

if [[ "$package_name" == pytorch ]]; then

    mkdir $final_dir/libtorch || true
    pushd pytorch_builder

    for ((i=0;i<${#CUDA_VERSIONS[@]};++i)); do
	CUDA_VERSION=${CUDA_VERSIONS[i]}
	CUDA_VERSION_FINAL=${CUDA_VERSIONS_FINAL[i]}
	CUDA_FOLDER=${CUDA_FOLDERS[i]}
	mkdir -p $final_dir/libtorch/$CUDA_VERSION_FINAL
	git checkout remotes/origin/wheels_3${CUDA_VERSION}
	cp wheels/$CUDA_FOLDER/* $final_dir/libtorch/$CUDA_VERSION_FINAL
	git checkout remotes/origin/wheels_3${CUDA_VERSION}_debug
	cp wheels/$CUDA_FOLDER/* $final_dir/libtorch/$CUDA_VERSION_FINAL
    done
fi
