# wrapper instance setup

## install the wrapper on the jenkins box

```
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install -y git htop iotop tmux

cd builder/nimbix-admin

source ~/env/bin/activate
pip install -U pip
pip install -U wheel
pip install -U setuptools
pip install pyyaml
pip install requests

pip install -r requirements.txt
pip install -r wrapper-service/requirements.txt

ln -s ../config.yaml config.yaml

cd wrapper-service
cp config.yaml.templ config.yaml
vim config.yaml
# it should look something like, see below
```
wrapper-service/config.yaml should look something like:
```
image: t1
instance_type: ngd3
max_time_minutes: 40
shared_secret: CHANGEME
script: |
  cd /tmp
  rm -Rf /tmp/builder
  sudo apt-get install -y git
  git clone git@github.com:pytorch/builder.git
  cd builder
  bash nimbix-bootstrap.sh {commit_hash}
```
- you'll need to fill in shared_secret with the value from ~/builder/config.yaml
- the rest should be approximately correct already

back in the ssh prompt:
```
cat >~/nimbix-start.sh <<EOF
#!/bin/bash
cd ~/builder/nimbix-admin
source ~/env/bin/activate
PYTHONPATH=. python wrapper-service/nimbix-wrapper.py --loglevel debug
EOF
```

Configure the nimbix wrapper:
```
cd ~/builder/nimbix-admin
cp nimbix.yaml.templ nimbix.yaml
vi nimbix.yaml
# change username and apikey to values from nimbix.
# you can get the apikey from Nimbix Dashboard -> [click on your username on top right] -> Account Settings -> General -> API Key
```

## start the wrapper

Need to do now, and after any instance restart:
```
# ssh into wrapper instance, and then
screen -R -D "nimbixwrapper"
ssh drop.jarvice.com
# accept the host key, then ctrl-c out when it asks for password
bash ~/nimbix-start.sh
```
=> the wrapper process should start.  You can try running from the jenkins instance:
```
curl -d 'h=123&s=changeme' 'http://localhost:3237/run'
```
... where:
- `h` value looks like a commit hash (<= 40 characters, only a-e, and 0-9 allowed)
- `s` value is shared secret value


