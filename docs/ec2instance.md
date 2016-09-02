# Create EC2 always-up t2.micro instance

- go to http://console.aws.amazon.com
  - sign in, or create account
- top right, check says 'N Virginia'
  - ![select region](docs/img/selectregion.png?raw=true)
- click on 'EC2'
  - ![clickec2](docs/img/clickec2.png?raw=true)
- click 'instances'
  - ![click instances](docs/img/clickinstances.png?raw=true)
- click 'launch instnace'
  - ![click launch instance](docs/img/clicklaunchinstance.png?raw=true)
- select ubuntu 14.04
  - ![select ubuntu 14.04](docs/img/selectubuntu1404.png?raw=true)
- choose t2.micro
  - ![choose t2.micro](docs/img/chooset2micro.png?raw=true)
- click configure instance details
  - ![click configure instance details](docs/img/clickconfigureinstancedetails.png?raw=true)
- tick 'protect against accidental termination'
  - ![tick protect](docs/img/tickprotect.png?raw=true)
- instance details should look *approximately* like:
  - ![approximate instance details](docs/img/approximateinstancedetails.png?raw=true)
- click 'Add Storage'
- change storage size to 30GB:
  - ![change storage 30GB](docs/img/changesize30.png?raw=true)
- click 'Tag Instance'
- click 'Configure Security Group'
- fill in:
  - security group name= torch-jenkins
  - description: torch-jenkins
- click 'Add Rule'
  - port: 8080
  - source: Anywhere
- click 'Add Rule'
  - port: 8443
  - source: Anywhere
- click 'Add Rule'
  - port: 80
  - source: Anywhere
- click 'Add Rule'
  - port: 443
  - source: Anywhere
- should look like:
  - ![security group](docs/img/securitygroup.png?raw=true)
- click 'review and launch'
- click 'launch'
- select 'create a new key pair'
  - name: torchjenkins
  - click 'download key pair', and save it somewhere
  - ![keypair](docs/img/keypair.png?raw=true)
- click 'launch instances'
- click 'view instances'
- (you'll see the instance in 'pending' for now)

Assign a static ip address:
- click 'elastic ips'
  - ![click elastic ips](docs/img/clickelasticips.png?raw=true)
- click 'allocate new address'
- change to 'VPC':
  - ![changetovpc](docs/img/changetovpc.png?raw=true)
- click 'yes, allocate'
- click 'close'
- in 'actions' select 'associate address'
- click in the 'instance' box (spinny will appear)
  - select your instance (i-something, like i-123456, or something)
- click 'associate'
  - ![associate](docs/img/associate.png?raw=true)
- _note down the ip address_, the one labelled 'elastic ip', probably starts with `52.` or `54.`
  - in doc below, this ip will be denoted as `$JENKINS_IP`

By now, your instance should be up, switch to a unix-y console. You'll need the keypair file you
downloaded earlier, ie torchjenkins.pem:
```
chmod 600 torchjenkins.pem
ssh -i torchjenkins.pem ubuntu@$JENKINS_IP
# click 'yes' I want to connect
# you're in :-)
# add public key for anyone who should be able to connect into .ssh/authorized_keys
exit
```

