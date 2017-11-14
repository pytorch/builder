yes | pip install visdom
pushd pytorch-a2c-ppo-acktr

# Assuming we're inside the docker image...
# Necessary for opencv-python
apt-get -qq update
apt-get -qq -y install libopencv-dev
yes | pip install opencv-python

# Name change so that one doesn't import baselines directly when inside pytorch-a2c-ppo-acktr
git clone https://github.com/openai/baselines.git baselines-repo
pushd baselines-repo

# mpi4py strugges to install the normal way
sed -i -e "s/'mpi4py',//g" setup.py
yes | conda install mpi4py

# Fixes https://github.com/openai/baselines/issues/197
sed -i -e 's/from baselines.bench.simple_bench import simple_bench//g' baselines/bench/__init__.py
pip install -e .
popd

pip install -r requirements.txt
popd
