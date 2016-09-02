# github configuration

## Pre-requisites

- admin access to cutorch repo
- email address to use for the new `torchbot` github account
- ip address of jenkins server
- shared secret, for connection to jenkins server (let's just re-use the jenkins password?)

## Procedure

### Create new torchbot github user

- in github, logout, then signup for a new account, eg `torchbot`
- keep the password safe somewhere (maybe just reuse the jenkins password?)
- go to https://github.com/settings/tokens
- click on 'generate new token'
  - description: 'jenkins'
  - tick 'repo'
  - click 'generate token'
  - note down this token, call it `$TORCHBOTTOKEN`

### Add `torchbot` as collaborator to `cutorch` repo

- logout of github, log in with cutorch repo admin account
- in https://github.com/torch/cutorch/settings , click on 'collaborators', put in your password, add `torchbot` as a collaborator
- copy the invitation link that it proposes
- logout, and login as `torchbot`, and navigate to the url you just copied, to activate the collaboration

### Configure webhook

- log into github with cutorch admin account
- go to https://github.com/torch/cutorch/settings/hooks
- click on 'Add webhook'
   - payload url should be: `https://jenkins:$JENKINSPASS@$JENKINSIP/ghprbhook/`  (replace `$JENKINSPASS` and `$JENKINSIP` with the actual concrete values for these)
   - secret: put the jenkins/github shared secret.  I think we can just reuse the jenkins password here?
   - click on 'disable ssl verification', and accept the popup warning
   - click on 'let me select individual events'
   - select 'pull request' and 'issue comment'
   - click on 'update webhook'

