# nimbix scripts

Use to start/stop nimbix instances, ssh to them, or simply run a single command on them, in batch mode

## Contents

* interactive usage
* batch usage
* systray icon

## Interactive Usage

### start
```
./nimbix-launch --type ng0 --image foo
```
... for bitstream boost, and assuming you created an image called `foo`, or:
```
./nimbix-launch --type ngd3 --image foo2
```
... for dual Titan X instance, assuming you have an image called `foo2`

### ssh

eg if you want to connect to an instance created from an image called `foo`, do:
```
./nimbix-ssh --image foo
```
This assumes you have added your ssh publickey to your nimbix account

Note that this turns off hostkey checking.  You may or may not want to do this (risk of man-in-middle attacks)

### shutdown

eg if you want to shut down an instance running from an image called `foo`, do:
```
./nimbix-shutdown --image foo
```

## Batch Usage

(doc in progress)

### run.py - run a single command, then exit

eg, to run `hostname`, on instance type `ng0`, using an image called `s1`:
```
./nimbix-run --type ng0 --image s1 hostname
```

Output:
```
command ['hostname']
jobnumber 66999
Opening Vault...
Initializing NAE...
CPU cores count:  2
CPU thread count: 2
passwd: password expiry information changed.
passwd: password expiry information changed.
Starting NAE...
Initializing networking...
NAE started in 1 second(s).

JARVICE
wall time 00:00:08
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
./nimbix-script --type ng0 --image s1 /tmp/test.sh
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

## systray icon

If you are on ubuntu:

* run `nimbix-indicator`
* an icon should appear in the notifications are
* if you start instances, their type should appear as a label next to the icon

Tested using xfce on ubuntu 16.04

## prerequisites / setup

- have python 3 installed (probably runs on python 2, but not tested)
- create a virtualenv, activate it, and run:
```
pip install -r requirements.txt
```
- copy `nimbix.yaml.templ` to `nimbix.yaml` and customize it with your username and nimbix apikey

