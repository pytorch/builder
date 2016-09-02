# pytorch builder

Scripts to build pytorch in Jenkins / Nimbix for continuous integration and building binaries

# Getting started

1. Setup an ec2 machine according to instructions from docs/ec2instance.md
1. Sign up for NIMBIX  according to instructions from docs/nimbixsignup.md
1. Create a github bot called "pytorchbot" according to instructions from docs/githubconfiguration.md
1. On the ec2 machine, [setup an ssh key](https://help.github.com/articles/generating-an-ssh-key/) and add it to the "pytorchbot" github account
1. SSH into the ec2 instance, and run:

```bash
cd ~/
sudo apt-get update -y
sudo apt-get install -y git
git clone git@github.com:pytorch/builder.git
cp builder/config.yaml.templ builder/config.yaml
```

1. Change the jenkinspassword and shared_secret in builder/config.yaml
1. Then run:

```bash
bash builder/installjenkins.sh
```
