# nimbix scripts

Use to start/stop nimbix instances, and ssh to them

## Usage

### start
```
python launch.py --type dg0 --image foo
```
... for bitstream boost, and assuming you created an image called `foo`, or:
```
python launch-standard.py --type ngd3 --image foo2
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

## prerequisites / setup

- have python 3 installed (probably runs on python 2, but not tested)
- create a virtualenv, activate it, and run:
```
pip install -r requirements.txt
```
- copy `nimbix.yaml.templ` to `nimbix.yaml` and customize it with your username and nimbix apikey

