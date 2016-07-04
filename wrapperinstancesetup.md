# wrapper instance setup

The wrapper contains the nimbix apikey.  This instance should be well secured, since the apikey gives full access to start instances, running arbitrary scripts.

## create ec2 nano instance

same as for jenkins, but:
- use a `nano`, since cheaper, and its not going to be taking any load
- 20GB disk is largely sufficient (can probalby get away with somewhere around 8-12 actually)
- incoming port is: 3437

Detailed procedure:
- go to http://console.aws.amazon.com
  - sign in, or create account
- top right, check says 'N Virginia'
  - ![select region](img/selectregion.png?raw=true)
- click on 'EC2'
  - ![clickec2](img/clickec2.png?raw=true)
- click 'instances'
  - ![click instances](img/clickinstances.png?raw=true)
- click 'launch instnace'
  - ![click launch instance](img/clicklaunchinstance.png?raw=true)
- select ubuntu 14.04
  - ![select ubuntu 14.04](img/selectubuntu1404.png?raw=true)
- choose t2.nano
- click configure instance details
  - ![click configure instance details](img/clickconfigureinstancedetails.png?raw=true)
- tick 'protect against accidental termination'
  - ![tick protect](img/tickprotect.png?raw=true)
- instance details should look *approximately* like:
  - ![approximate instance details](img/approximateinstancedetails.png?raw=true)
- click 'Add Storage'
- change storage size to 20GB:
- click 'Tag Instance'
- click 'Configure Security Group'
- fill in:
  - security group name= nimbix-wrapper
  - description: nimbix-wrapper
- click 'Add Rule'
  - port: 3237
  - source: Anywhere  (ideally, put the jenkins ip address actually)
- click 'review and launch'
- click 'launch'
- select 'create a new key pair'
  - name: nimbixwrapper
  - click 'download key pair', and save it somewhere
- click 'launch instances'
- click 'view instances'
- (you'll see the instance in 'pending' for now)

Assign a static ip address:
- click 'elastic ips'
  - ![click elastic ips](img/clickelasticips.png?raw=true)
- click 'allocate new address'
- change to 'VPC':
  - ![changetovpc](img/changetovpc.png?raw=true)
- click 'yes, allocate'
- click 'close'
- in 'actions' select 'associate address'
- click in the 'instance' box (spinny will appear)
  - select your instance (i-something, like i-123456, or something)
- click 'associate'
  - ![associate](img/associate.png?raw=true)
- _note down the ip address_, the one labelled 'elastic ip', probably starts with `52.` or `54.`
  - in doc below, this ip will be denoted as `$WRAPPER_IP`

By now, your instance should be up, switch to a unix-y console. You'll need the keypair file you
downloaded earlier, ie nimbixwrapper.pem:
```
chmod 600 nimbixwrapper.pem
ssh -i nimbixwrapper.pem ubuntu@$WRAPPER_IP
# click 'yes' I want to connect
# you should connect ok
exit
```

## install the wrapper

From ssh into the wrapper intsance, do approximately (since I havent tested this, just kind of from memory...):
```
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install -y git htop iotop tmux
sudo apt-get install -y python3.4-dev python-virtualenv python-wheel

git clone https://github.com/hughperkins/nimbix-admin
cd nimbix-admin

virtualenv -p python3 env
source env/bin/activate
pip install -U pip
pip install -U wheel
pip install -U setuptools
pip install pyyaml
pip install requests

pip install -r requirements.txt
pip install -r wrapper-service/requirements.txt

cp config.yaml.templ config.yaml
vim config.yaml
# configure as for the jenkins instance

cd wrapper-service
cp config.yaml.templ config.yaml
vim config.yaml
# it should look something like, see below
```
wrapper-service/config.yaml should look something like:
```
image: ngd3
instance_type: ngd3
max_time_minutes: 40
allowed_client_ip: 52.0.1.2
shared_secret: changeme
script: |
  cd /tmp
  rm -Rf /tmp/torchunit
  git clone https://github.com/hughperkins/torchunit
  cd torchunit
  bash nimbix-bootstrap.sh {commit_hash}
```
- you'll need to fill in shared_secret with some value you create (security perimeter for this value: this box + jenkins box)
- fill in the public ip address of the jenkins box (ie the value of `$JENKINS_IP`)
- the rest should be approximately correct already

back in the ssh prompt:
```
cat >~/start.sh <<EOF
#!/bin/bash
cd nimbix-admin
source env/bin/activate
PYTHONPATH=. python wrapper-service/nimbix-wrapper.py --loglevel debug
EOF
```

## start the wrapper

Need to do now, and after any instance restart:
```
# ssh into wrapper instance, and then
tmux
bash start.sh
```
=> the wrapper process should start.  You can try running from the jenkins instance:
```
curl -d 'h=123&s=changeme' 'http://52.1.2.3.4/run'
```
... where:
- `h` value looks like a commit hash (<= 40 characters, only a-e, and 0-9 allowed)
- `s` value is shared secret value

