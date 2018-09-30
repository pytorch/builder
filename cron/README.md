# Pytorch Binary Nightly Cron Jobs

This folder contains all the scripts needed for nightly cron jobs which build
and upload the Pytorch binaries every night.

# Entrypoints

To manually build a single package:

    cron/build_mac.sh (conda|wheel|libtorch) py_version
    Builds either a conda package or wheel for Mac (it must be run on a Mac).

    cron/build_docker.sh (conda|manywheel|libtorch) py_version cuda_version
    Builds either a conda package, manywheel, or libtorch package in a docker.

To manually build multiple packages:
    cron/build_multiple.sh (conda|manywheel|wheel|libtorch) pyver[,py_ver...] cuda_ver[,cuda_ver...]
    See the comment in cron/build_multiple.sh for example invocations. All packages will be built in serial. Essentially just calls into build_docker.sh or build_mac.sh

How cron builds packages:
Cron uses ./cron/start_cron.sh, which clones the latest builder repo and then calls cron/build_cron.sh in that. build_cron.sh contains the schedule (which jobs run on which machines) and starts a few queues of 4 jobs each in parallel on each machine. build_cron.sh will also upload the successful packages and clean old nightlies folders.


# How the scripts work

- 3 Linux machines and 1 Mac
- Started by cron every morning
- Each day a new nightlies folder is created like 2018_09_12 that holds all the
  builds for the day

# Example Program Flow

Let's say the date is September 12, 2018

* cron will run based on hellemn's crontab
* cron will call hellemn/builder/cron/cron_start.sh
  * This will clone the builder master into /scratch/hellemn/nightlies/2018_09_12/builder
  * N.B. how the crontab points to my personal builder checkout, which then clones master's builder and calls into that. This is so that we can always use the latest master of the builder repo without having to manually update the github checkouts on each machine. Caveat, if cron_start.sh is ever changed then the repos will have to be manually updated on every machine.
* nightlies/2018_09_12/builder/cron/build_cron.sh will be called with the machine number [0-2]. This machine number corresponds to the tasks in builder/cron/build_cron.sh, which delegates 13 builds to each machine in 4 parallel tasks
  * Each parallel task of 3-4 builds each is logged to 2018_09_12/logs/master/<a concatenation of all build names>
  * While a build is ongoing its output is logged to 2018_09_12/logs/packagetype_pythonversion_cpucudaversion.log. Whenever a build fails, its log is moved to 2018_09_12/logs/failed. When a build succeeds, its log is moved to 2018_09_12/logs/succeeded.
    * N.B., if the machine runs out of memory then sometimes these logs can't be written.
* When all builds finish, cron/upload.sh is called to upload the successful ones. This uses hellemn's credentials, which are sourced from a file that is not in the git repository.
* Since it's the 12th, all builds from the 5th earlier are deleted. In this case, rm -rf nightlies/2018_09_07 will be called.

# Folder structure

Each day's build creates a folder with the following structure

```
/scratch/hellemn/nightlies/2018_09_12/

    # The latest builder repo, pytorch/builder's master and pytorch/pytorch's master
    builder/
    pytorch/

    logs/
        master/
            # cron_start.log
            # build_cron.log
            # upload.log
            # Logs for build_multiple.sh calls,
            #   e.g. manywheel_2.7m2.7mu3.5m_cu92.log

        # When builds finish their logs are moved to one of these folders
        failed/
        succeeded/

        # Currently running builds will have their logs here
        # e.g. manywheel_3.6_cpu.log

    # These subdirs hold final built packages. Not all subdirs will exist,
    # depending on the jobs running on this machine. Packages are copied here
    # after dependencies are tweaked with but before any testing is done, so
    # they may be broken.
    wheelhousecpu/
    wheelhouse80/
    wheelhouse90/
    wheelhouse92/
    conda_pkgs/
    mac_wheels/
    mac_conda_pkgs/

    # On mac builds, each build also gets their own folder with their own copy
    # pytorch and conda to ensure they don't interfere with each other
    wheel_build_dirs/
        wheel_3.6_cpu/
            conda/
            pytorch/
            dist/   # Unfinished packages
```

