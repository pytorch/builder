#!/usr/bin/env python3

import boto3
import os
import subprocess


# CONSTANTS
ubuntu18_04_ami = "ami-0f2b111fdc1647918"
ubuntu20_04_ami = "ami-0ea142bd244023692"
keyfile_path = os.path.join(os.path.expanduser("~"), ".ssh", "nshulga-key.pem")


ec2 = boto3.resource("ec2")

def ec2_get_instances(filter_name, filter_value):
   return ec2.instances.filter(Filters=[{'Name': filter_name, 'Values' : [filter_value]}])

def ec2_instances_of_type(instance_type = 't4g.2xlarge'):
   return ec2_get_instances('instance-type', instance_type)

def ec2_instances_by_id(instance_id):
   rc = list(ec2_get_instances('instance-id', instance_id))
   return rc[0] if len(rc) > 0 else None


def start_instance(ami = ubuntu18_04_ami):
    inst = ec2.create_instances(ImageId=ami, InstanceType='t4g.2xlarge', SecurityGroups=['ssh-allworld'], KeyName='nshulga-key', MinCount=1, MaxCount=1)[0]
    print(f'Create instance {inst.id}')
    inst.wait_until_running()
    running_inst = ec2_instances_by_id(inst.id)
    print(f'Instance started at {running_inst.public_dns_name}')
    return running_inst

def run_ssh(addr, args):
   subprocess.check_call(["/usr/bin/ssh", "-o", "StrictHostKeyChecking=no", "-i", keyfile_path, f"ubuntu@{addr}", "--"] + (args.split() if isinstance(args, str) else args))


def wait_for_connection(addr, port, timeout=5, attempt_cnt=5):
    import socket
    import time
    for i in range(attempt_cnt):
        try:
            with socket.create_connection((addr, port), timeout=timeout):
                return
        except (ConnectionRefusedError, socket.timeout):
            if i == attempt_cnt-1:
                raise
            time.sleep(timeout)


def start_build(ami = ubuntu18_04_ami, branch="master"):
    inst = start_instance(ami)
    addr = inst.public_dns_name
    wait_for_connection(addr, 22)
    print(f'Configuring the system')
    run_ssh(addr, "sudo apt-get update")
    run_ssh(addr, "sudo apt-get install -y ninja-build g++ git cmake python3-dev gfortran")
    run_ssh(addr, "sudo apt-get install -y python3-yaml python3-setuptools python3-wheel python3-pip")
    run_ssh(addr, "sudo pip3 install dataclasses")
    # Installing Cython and numpy
    run_ssh(addr, "sudo pip3 install Cython")
    run_ssh(addr, "sudo pip3 install numpy")
    # Build OpenBLAS
    print('Building OpenBLAS')
    run_ssh(addr, "git clone https://github.com/xianyi/OpenBLAS -b v0.3.10")
    run_ssh(addr, "cd OpenBLAS; make NO_SHARED=1 -j8; sudo make NO_SHARED=1 install")

    print('Checking out the repo')
    run_ssh(addr, f"git clone --recurse-submodules -b {branch} https://github.com/pytorch/pytorch")
    print('Building PyTorch wheel')
    run_ssh(addr, "cd pytorch ; python3 setup.py bdist_wheel")
    print('Copying the wheel')
    subprocess.check_call(["/usr/bin/scp", "-i", keyfile_path, f"ubuntu@{addr}:pytorch/dist/*.whl", "."])

    print(f'Waiting for instance {inst.id} to terminate')
    inst.terminate()
    inst.wait_until_terminated()

def start_test(ami, whl):
    inst = start_instance(ami)
    addr = inst.public_dns_name
    wait_for_connection(addr, 22)
    print(f'Configuring the system')
    run_ssh(addr, "sudo apt-get update")
    run_ssh(addr, "sudo apt-get install -y python3-pip")

if __name__ == '__main__':
    start_build(ubuntu20_04_ami, branch='malfet/static-openblas-detection')
