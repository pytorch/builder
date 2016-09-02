# nimbix signup

- go to http://nimbix.net
- click 'login'
  - ![click login](docs/img/nimbixlogin.png?raw=true)
- click 'signup'
  - ![click signup](docs/img/nimbixsignup.png?raw=true)
- do the whole sign up thing, and login
- click 'Images'
  - ![click images](docs/img/nimbiximages.png?raw=true)
- click 'Create'
- put:
  - name: t1
  - template: Ubuntu-14.04
  - ![create image](docs/img/nimbixcreateimage.png?raw=true)
  - click 'Dismiss'
- quick background: the 'image' is basically an instance, in ec2 parlance.  It's a persistent operating system
installation, that you can install things into.

Now, we get to a sensitive bit.
- The APIKEY gives full access to run jobs using this account.  There's no
obvious upper bound to how many jobs one can run in parallel, or on what instances... so it's a bit
sensitive...
- You will get emailed, spammed really, every time a job starts/stops, but its so spammy, you'll filter it
out within hours, and ignore it.  So that's not going to help much
- I was originally going to ask for the APIKEY, thinking the billing is upperbounded by number-images *
maximum-billing-rate, but actually you can run ephemeral jobs, so there's no such upper bound
  - a related possibility is, dont give me the apikey, but click your username in topright, click on 'account settings',
then 'team', then 'add' then invite other people, whose usage will be billed to your account, but you will at 
least see in the billing who has used what
  - this still isnt really ideal if there will be multiple people with access to jenkins (which there probably
  will be plausibly?)
- I'm thinking as I write really.  A couple of possibilities:
  - run a webservice somewhere, eg on a second ec2 instance perhaps?, that only you
  have access to, and that strictly only runs non-ephemeral launches
    - this will at least upper-bound the cost to number-images * maximum-rate
    - and means no-one else has the apikey
  - dont give anyone else access to jenkins box, at least, not ssh login, nor admin rights to jenkins, nor
  very extensive rights to jenkins at all
     - jenkins will spin up from a script, in a github repo, that anyone can contribute to, push pull requests to, etc
     - only you will ever login to the jenkins box, clone the github repo, and run said script
- as I write, I quite like the second option.  It's cleaner anyway.  Easy to reinstall the instance if it goes down

