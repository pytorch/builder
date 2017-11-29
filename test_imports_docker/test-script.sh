set -ex

# Runs a script on a container with the image.

IMAGE=$1 # e.g. ubuntu:12.04
# The other arguments, 2-..., are script names, ie install-conda-ubuntu.sh
sudo docker run -d --name img -it --rm -v $(pwd):/remote $IMAGE /bin/bash 
# Run the rest of the argument as scripts
for var in "${@:2}"; do
  sudo docker exec img /remote/$var
done
sudo docker stop img

