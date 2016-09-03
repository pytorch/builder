# github configuration

## Pre-requisites

- admin access to pytorch repo
- email address to use for the new `torchbot` github account

## Procedure

### Create new torchbot github user

- in github, logout, then signup for a new account, eg `torchbot`
- keep the password safe somewhere
- go to https://github.com/settings/tokens
- click on 'generate new token'
  - description: 'jenkins'
  - tick 'repo'
  - click 'generate token'
  - note down this token, call it `$TORCHBOTTOKEN`

### Add `torchbot` as collaborator to `pytorch` repo

- logout of github, log in with pytorch repo admin account
- in https://github.com/torch/pytorch/settings , click on 'collaborators', put in your password, add `torchbot` as a collaborator
- copy the invitation link that it proposes
- logout, and login as `torchbot`, and navigate to the url you just copied, to activate the collaboration

### Configure webhook

- log into github with pytorch admin account
- go to https://github.com/torch/pytorch/settings/hooks
- click on 'Add webhook'
   - payload url should be: `https://jenkins:$JENKINSPASS@build.pytorch.org/ghprbhook/`  (replace `$JENKINSPASS` with the actual value)
   - secret: $JENKINSPASS (replace `$JENKINSPASS` with the actual value)
   - click on 'let me select individual events'
   - select 'pull request' and 'issue comment'
   - click on 'update webhook'

