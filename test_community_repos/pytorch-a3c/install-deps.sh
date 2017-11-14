yes | pip install gym
yes | pip install gym[atari]

# Assuming we're inside the docker image...
# Necessary for cv2
apt-get -qq update
apt-get -qq -y install libopencv-dev
yes | pip install opencv-python
