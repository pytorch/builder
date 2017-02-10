# pytorch builder

Scripts to build pytorch in Jenkins / Nimbix for continuous integration and building binaries

# Getting started

* Setup an ec2 machine according to instructions from docs/ec2instance.md
* Sign up for NIMBIX  according to instructions from docs/nimbixsignup.md
* Create a github bot called "pytorchbot" according to instructions from docs/githubconfiguration.md
* On the ec2 machine, [setup an ssh key](https://help.github.com/articles/generating-an-ssh-key/) and add it to the "pytorchbot" github account
* SSH into the ec2 instance, and run:

```bash
cd ~/
sudo apt-get update -y
sudo apt-get install -y git
git clone git@github.com:pytorch/builder.git
cp builder/config.yaml.templ builder/config.yaml
```

* Change the jenkinspassword and shared_secret in builder/config.yaml
* Then run this and follow instructions:

```bash
bash builder/installjenkins.sh
```

* Then start jenkins

```bash
bash builder/runjenkins.sh
```

* Follow the instructions in docs/jenkins.md
* Follow the instructions in docs/wrapperinstancesetup.md

* Finally, run these commands so that http://build.pytorch.org gets forwarded to https:// automatically
```bash
sudo apt-get install -y nginx
sudo service nginx stop
sudo rm /etc/nginx/sites-enabled/default
cat <<EOF | sudo tee /etc/nginx/sites-available/redirect-https
server {
    listen         80;
	return 302 https://\$host\$request_uri;
}
EOF
sudo ln -sf /etc/nginx/sites-available/redirect-https /etc/nginx/sites-enabled/redirect-https
sudo service nginx start
```


#### Renew certificates for letsencrypt
- kill jenkins
- ./certbot-auto renew
- bash builder/runjenkins.sh
