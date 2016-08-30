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
image: t1
instance_type: ngd3
max_time_minutes: 40
allowed_client_ip: $JENKINS_IP
shared_secret: changeme
script: |
  cd /tmp
  rm -Rf /tmp/torchunit
  sudo apt-get install -y git
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

Configure the nimbix wrapper:
```
cd ~/nimbix-admin
cp nimbix.yaml.templ nimbix.yaml
vi nimbix.yaml
# change username and apikey to values from nimbix.
# you can get the apikey from Nimbix Dashboard -> [click on your username on top right] -> Account Settings -> General -> API Key
```

## start the wrapper

Need to do now, and after any instance restart:
```
# ssh into wrapper instance, and then
tmux
ssh drop.jarvice.com
# accept the host key, then ctrl-c out when it asks for password
bash start.sh
```
=> the wrapper process should start.  You can try running from the jenkins instance:
```
curl -d 'h=123&s=changeme' 'http://52.1.2.3.4/run'
```
... where:
- `h` value looks like a commit hash (<= 40 characters, only a-e, and 0-9 allowed)
- `s` value is shared secret value

## Analysis of possible future maintenance required

- if jenkins instance ip changes:
  - update the security group to have new jenkins ip
  - update the `wrapper-service/config.yaml` with the new jenkins ip
- if instance gets bounced (eg from some kind of aws maintenance, which is rare, ~once a year):
  - follow instructions in section `start the wrapper`
- if switch bootstrap script, eg from `https://github.com/hughperkins/torchunit` to eg `https://github.com/torch/torchunit`:
  - modify the script in `wrapper-service/config.yaml`, to point to new repo
  - kill tmux process
  - follow the instructions in `start the wrapper`
- if api key changes:
  - modify config.yaml
  - kill tmux process
  - follow the instructions in `start the wrapper`

## Security analysis

- what if someone can push rogue instructions into `https://github.com/hughperkins/torchunit` or `https://github.com/torch/torchunit`?
  - this affects what is run on the nimbix instances themselves, but doesnt actually run anything on the wrapper instance, therefore no obvious way in which this would expose the apikey
  - of course, running arbitrary scripts on an internet-based server gives quite a lot of possibilities...
- what if someone can push rogue instructions into `https://github.com/hughperkins/nimbix-admin`?
  - only matters if they are there at the time the repo is cloned onto wrapper instance
  - nothing in these instructions ever updates that repo (ie no `git pull`), so future changes wont affect anything
- what if someone has `shared secret`?
  - they still need to obtain access to jenkins box, in order to run anything
  - they still cant obtain the nimbix api key
  - they still cant modify which script is run
  - all they can do is run torch unit tests over and over again :-)
- what if someone sniffs the (non-ssl..) traffic?
  - they obtain the shared key
  - see section `what if someone has shared secret?` above
- is the `shared secret` really necessary at all?
  - defense in depth really
- what if someone hacks into the wrapper instance itself?
  - yes, then the api key is exposed, this is not ideal...
- update and so on: if system update are not run regularly, will zero-days be exposed?
  - the security perimeter is pretty small: just one single web-service, with one single end-point
  - there is not even any reliance on ssl working correctly
  - limited opportunity to interact with the service
  - no obvious way to interact directly with the kernel
  - since no obvious fixed-size buffers involved, limited opportunity to overflow some service buffer
  - probalby the main way is...
- if the nimbix service is hacked, and returns malicious data, this has a relatively large attack surface
  - but if nimbix service is hacked, a lot of nimbix-related security aspects will become questionable at that point anyway
  - but might want to double-check the attack surface associated with data returned from a compromised nimbix service
- disclaimer: this security analysis is best effort, and there are certainly attack vectors not listed here.  There may be things asserted here which are not correct.  You should make your own security analysis.  This analysis is indicative of certain things that might happen only.

