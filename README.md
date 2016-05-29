# nimbix scripts

Use to start/stop nimbix instances, ssh to them, or simply run a single command on them, in batch mode

## Interactive Usage

### start
```
python launch.py --type dg0 --image foo
```
... for bitstream boost, and assuming you created an image called `foo`, or:
```
python launch.py --type ngd3 --image foo2
```
... for dual Titan X instance, assuming you have an image called `foo2`

### ssh

eg if you want to connect to an instance created from an image called `foo`, do:
```
./ssh.sh --image foo
```
This assumes you have added your ssh publickey to your nimbix account

### shutdown

eg if you want to shut down an instance running from an image called `foo`, do:
```
python shutdown.py --image foo
```

## Batch Usage

(doc in progress)

### run.py - run a single command, then exit

eg, to run `hostname`, on instance type `ng0`, using an image called `s1`:
```
python run.py --type ng0 --image s1 hostname
```

Output:
```
command ['hostname']
res.status_code 200
jobnumber 66957
   PROCESSING STARTING
   PROCESSING STARTING
   PROCESSING STARTING
   PROCESSING STARTING
   COMPLETED
Opening Vault...
Initializing NAE...
CPU cores count:  2
CPU thread count: 2
passwd: password expiry information changed.
passwd: password expiry information changed.
Starting NAE...
Initializing networking...
NAE started in 2 second(s).

JARVICE



wall time 00:00:09
```

### script.py - run a single batch script, then exit

copies the named script to your `/data` folder, then runs it, and shows the output

eg:
```
cat >/tmp/test.sh<<EOF
#!/bin/bash
hostname
env
EOF
python script.py --type ng0 --image s1 /tmp/test.sh
```

Output:
```
tmp/test.sh
scriptPath /tmp/test.sh
scriptName test.sh
jobnumber 66988
Opening Vault...
Initializing NAE...
CPU cores count:  2
CPU thread count: 2
passwd: password expiry information changed.
passwd: password expiry information changed.
Starting NAE...
Initializing networking...
NAE started in 2 second(s).

JARVICE
USER=nimbix
USERNAME=nimbix
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PWD=/data
SHLVL=1
HOME=/home/nimbix
LOGNAME=nimbix
_=/usr/bin/env
wall time 00:00:08
```

## prerequisites / setup

- have python 3 installed (probably runs on python 2, but not tested)
- create a virtualenv, activate it, and run:
```
pip install -r requirements.txt
```
- copy `nimbix.yaml.templ` to `nimbix.yaml` and customize it with your username and nimbix apikey

