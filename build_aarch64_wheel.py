#!/usr/bin/env python3

import boto3
import os
import subprocess
import sys
import time
from typing import Tuple


# CONSTANTS
ubuntu18_04_ami = "ami-0f2b111fdc1647918"
ubuntu20_04_ami = "ami-0ea142bd244023692"
keyfile_path = os.path.join(os.path.expanduser("~"), ".ssh", "nshulga-key.pem")


ec2 = boto3.resource("ec2")


def ec2_get_instances(filter_name, filter_value):
    return ec2.instances.filter(Filters=[{'Name': filter_name, 'Values': [filter_value]}])


def ec2_instances_of_type(instance_type='t4g.2xlarge'):
    return ec2_get_instances('instance-type', instance_type)


def ec2_instances_by_id(instance_id):
    rc = list(ec2_get_instances('instance-id', instance_id))
    return rc[0] if len(rc) > 0 else None


def start_instance(ami=ubuntu18_04_ami, instance_type='t4g.2xlarge'):
    inst = ec2.create_instances(ImageId=ami,
                                InstanceType=instance_type,
                                SecurityGroups=['ssh-allworld'],
                                KeyName='nshulga-key',
                                MinCount=1,
                                MaxCount=1)[0]
    print(f'Create instance {inst.id}')
    inst.wait_until_running()
    running_inst = ec2_instances_by_id(inst.id)
    print(f'Instance started at {running_inst.public_dns_name}')
    return running_inst


def _gen_ssh_prefix(addr):
    return ["ssh", "-o", "StrictHostKeyChecking=no", "-i", keyfile_path, f"ubuntu@{addr}", "--"]


def run_ssh(addr, args):
    subprocess.check_call(_gen_ssh_prefix(addr) + (args.split() if isinstance(args, str) else args))


def check_output(addr, args):
    return subprocess.check_output(_gen_ssh_prefix(addr) + (args.split() if isinstance(args, str) else args)).decode("utf-8")


def list_dir(addr, path):
    return check_output(addr, ["ls", "-1", path]).split("\n")


def wait_for_connection(addr, port, timeout=5, attempt_cnt=5):
    import socket
    for i in range(attempt_cnt):
        try:
            with socket.create_connection((addr, port), timeout=timeout):
                return
        except (ConnectionRefusedError, socket.timeout):
            if i == attempt_cnt - 1:
                raise
            time.sleep(timeout)


def update_apt_repo(addr):
    time.sleep(5)
    run_ssh(addr, "sudo systemctl stop apt-daily.service || true")
    run_ssh(addr, "sudo systemctl stop unattended-upgrades.service || true")
    run_ssh(addr, "while systemctl is-active --quiet apt-daily.service; do sleep 1; done")
    run_ssh(addr, "while systemctl is-active --quiet unattended-upgrades.service; do sleep 1; done")
    run_ssh(addr, "sudo apt-get update")
    time.sleep(3)
    run_ssh(addr, "sudo apt-get update")


def install_condaforge(addr):
    print('Install conda-forge')
    run_ssh(addr, "curl -OL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh")
    run_ssh(addr, "sh -f Miniforge3-Linux-aarch64.sh -b")
    run_ssh(addr, ['sed', '-i', '\'/^# If not running interactively.*/i PATH=$HOME/miniforge3/bin:$PATH\'', '.bashrc'])


def embed_libgomp(addr, use_conda, wheel_name):
    run_ssh(addr, "pip3 install auditwheel")
    run_ssh(addr, "conda install -y patchelf" if use_conda else "sudo apt-get install -y patchelf")
    from tempfile import NamedTemporaryFile
    with NamedTemporaryFile() as tmp:
        tmp.write(embed_library_script.encode('utf-8'))
        tmp.flush()
        subprocess.check_call(["scp", "-i", keyfile_path, tmp.name, f"ubuntu@{addr}:embed_library.py"])

    print('Embedding libgomp into wheel')
    run_ssh(addr, f"python3 embed_library.py {wheel_name}")


def start_build(ami=ubuntu18_04_ami, branch="master", use_conda=True, python_version="3.8", keep_running=False) -> Tuple[str, str]:
    inst = start_instance(ami)
    addr = inst.public_dns_name
    wait_for_connection(addr, 22)
    if use_conda:
        install_condaforge(addr)
        run_ssh(addr, f"conda install -y python={python_version} numpy pyyaml")
    print('Configuring the system')
    update_apt_repo(addr)

    run_ssh(addr, "sudo apt-get install -y ninja-build g++ git cmake gfortran unzip")
    if not use_conda:
        run_ssh(addr, "sudo apt-get install -y python3-dev python3-yaml python3-setuptools python3-wheel python3-pip")
    run_ssh(addr, "pip3 install dataclasses")
    # Install and switch to gcc-8 on Ubuntu-18.04
    if ami == ubuntu18_04_ami:
        run_ssh(addr, "sudo apt-get install -y g++-8 gfortran-8")
        run_ssh(addr, "sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100")
        run_ssh(addr, "sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 100")
        run_ssh(addr, "sudo update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-8 100")
    if not use_conda:
        print("Installing Cython + numpy from PyPy")
        run_ssh(addr, "sudo pip3 install Cython")
        run_ssh(addr, "sudo pip3 install numpy")
    # Build OpenBLAS
    print('Building OpenBLAS')
    run_ssh(addr, "git clone https://github.com/xianyi/OpenBLAS -b v0.3.10")
    # TODO: Build with USE_OPENMP=1 support
    run_ssh(addr, "pushd OpenBLAS; make NO_SHARED=1 -j8; sudo make NO_SHARED=1 install;popd")

    print('Checking out PyTorch repo')
    run_ssh(addr, f"git clone --recurse-submodules -b {branch} https://github.com/pytorch/pytorch")
    print('Building PyTorch wheel')
    if branch == 'nightly':
        build_date = check_output(addr, "cd pytorch ; git log --pretty=format:%s -1").strip().split()[0].replace("-", "")
        version = check_output(addr, "cat pytorch/version.txt").strip()[:-2]
        run_ssh(addr, f"cd pytorch ; BUILD_TEST=0 PYTORCH_BUILD_VERSION={version}.dev{build_date} PYTORCH_BUILD_NUMBER=1 python3 setup.py bdist_wheel")
    else:
        run_ssh(addr, "cd pytorch ; python3 setup.py bdist_wheel")
    pytorch_wheel_name = list_dir(addr, "pytorch/dist")[0]
    embed_libgomp(addr, use_conda, os.path.join('pytorch', 'dist', pytorch_wheel_name))
    print('Copying the wheel')
    subprocess.check_call(["scp", "-i", keyfile_path, f"ubuntu@{addr}:pytorch/dist/*.whl", "."])

    print('Checking out TorchVision repo')
    run_ssh(addr, "git clone https://github.com/pytorch/vision")
    print('Installing PyTorch wheel')
    run_ssh(addr, f"pip3 install pytorch/dist/{pytorch_wheel_name}")
    print('Building TorchVision wheel')
    if branch == 'nightly':
        version = check_output(addr, ["grep", "\"version = '\"", "vision/setup.py"]).strip().split("'")[1][:-2]
        run_ssh(addr, f"cd vision; BUILD_VERSION={version}.dev{build_date} python3 setup.py bdist_wheel")
    else:
        run_ssh(addr, "cd vision; python3 setup.py bdist_wheel")
    vision_wheel_name = list_dir(addr, "vision/dist")[0]
    print('Copying TorchVision wheel')
    subprocess.check_call(["scp", "-i", keyfile_path, f"ubuntu@{addr}:vision/dist/*.whl", "."])

    if keep_running:
        return pytorch_wheel_name, vision_wheel_name

    print(f'Waiting for instance {inst.id} to terminate')
    inst.terminate()
    inst.wait_until_terminated()
    return pytorch_wheel_name, vision_wheel_name


embed_library_script = """
#!/usr/bin/env python3

from auditwheel.patcher import Patchelf
from auditwheel.wheeltools import InWheelCtx
from auditwheel.elfutils import elf_file_filter
from auditwheel.repair import copylib
from auditwheel.lddtree import lddtree
import os
import shutil
import sys
from tempfile import TemporaryDirectory


def embed_library(whl_path, lib_soname):
    patcher = Patchelf()
    out_dir = TemporaryDirectory()
    whl_name = os.path.basename(whl_path)
    tmp_whl_name = os.path.join(out_dir.name, whl_name)
    with InWheelCtx(whl_path) as ctx:
        torchlib_path = os.path.join(ctx._tmpdir.name, 'torch', 'lib')
        ctx.out_wheel=tmp_whl_name
        new_lib_path, new_lib_soname = None, None
        for filename, elf in elf_file_filter(ctx.iter_files()):
            if not filename.startswith('torch/lib'):
                continue
            libtree = lddtree(filename)
            if lib_soname not in libtree['needed']:
                continue
            lib_path = libtree['libs'][lib_soname]['path']
            if lib_path is None:
                print(f"Can't embed {lib_soname} as it could not be found")
                break
            if lib_path.startswith(torchlib_path):
                continue

            if new_lib_path is None:
                new_lib_soname, new_lib_path = copylib(lib_path, torchlib_path, patcher)
            patcher.replace_needed(filename, lib_soname, new_lib_soname)
            print(f'Replacing {lib_soname} with {new_lib_soname} for {filename}')
    shutil.move(tmp_whl_name, whl_path)


if __name__ == '__main__':
    whl_name='torch-1.8.0.dev20201108-cp38-cp38-linux_aarch64.whl'
    embed_library(sys.argv[1], 'libgomp.so.1')
"""


def run_tests(ami, whl, branch='master'):
    inst = start_instance(ami)
    addr = inst.public_dns_name
    wait_for_connection(addr, 22)
    print(f'Configuring the system')
    update_apt_repo(addr)
    run_ssh(addr, "sudo apt-get install -y python3-pip git")
    run_ssh(addr, "sudo pip3 install Cython")
    run_ssh(addr, "sudo pip3 install numpy")
    subprocess.check_call(["scp", "-i", keyfile_path, whl, f"ubuntu@{addr}:"])
    run_ssh(addr, f"sudo pip3 install {whl}")
    run_ssh(addr, "python3 -c 'import torch;print(torch.rand((3,3))'")
    run_ssh(addr, f"git clone -b {branch} https://github.com/pytorch/pytorch")
    run_ssh(addr, "cd pytorch/test; python3 test_torch.py -v")


def list_instances(instance_type: str) -> None:
    print(f"All instances of type {instance_type}")
    for instance in ec2_instances_of_type(instance_type):
        print(f"{instance.id} {instance.public_dns_name} {instance.state['Name']}")


def terminate_instances(instance_type: str) -> None:
    print(f"Terminating all instances of type {instance_type}")
    instances = list(ec2_instances_of_type(instance_type))
    for instance in instances:
        print(f"Terminating {instance.id}")
        instance.terminate()
    print(f"Waiting for termination to complete")
    for instance in instances:
        instance.wait_until_terminated()


def parse_arguments():
    from argparse import ArgumentParser
    parser = ArgumentParser("Builid and test AARCH64 wheels using EC2")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--build-only", action="store_true")
    parser.add_argument("--test-only", type=str)
    parser.add_argument("--os", type=str, choices=['ubuntu18_04', 'ubuntu20_04'], default='ubuntu18_04')
    parser.add_argument("--python-version", type=str, choices=['3.6', '3.7', '3.8'], default=None)
    parser.add_argument("--alloc-instance", action="store_true")
    parser.add_argument("--list-instances", action="store_true")
    parser.add_argument("--keep-running", action="store_true")
    parser.add_argument("--terminate-instances", action="store_true")
    parser.add_argument("--instance-type", type=str, default="t4g.2xlarge")
    parser.add_argument("--branch", type=str, default="master")
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_arguments()
    ami = ubuntu20_04_ami if args.os == 'ubuntu20_04' else ubuntu18_04_ami

    if args.list_instances:
        list_instances(args.instance_type)
        sys.exit(0)

    if args.terminate_instances:
        terminate_instances(args.instance_type)
        sys.exit(0)

    if args.test_only:
        run_tests(ami, args.test_only)
        sys.exit(0)

    if args.alloc_instance:
        inst = start_instance(ami, args.instance_type)
        if args.python_version is None:
            sys.exit(0)
        addr = inst.public_dns_name
        wait_for_connection(addr, 22)
        install_condaforge(addr)
        run_ssh(addr, f"conda install -y python={args.python_version} numpy pyyaml")
        sys.exit(0)

    python_version = args.python_version if args.python_version is not None else '3.8'
    start_build(ami, branch=args.branch, python_version=python_version, keep_running=args.keep_running)
