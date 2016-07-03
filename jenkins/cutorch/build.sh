# this will be running on the jenkins instance (ie not on nimbix instance)
#
# it is responsible for:
# - bringing up a nimbix instance / running a nimbix job
# - said nimbix job should then handle building torch, cutorch, running cutorch unit tests

# for now, this just says hello and stuff

echo test
env | grep GIT
git log -n 3 --oneline
git status

