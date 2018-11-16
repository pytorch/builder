#!/bin/bash

set -ex

# Default parameters for nightly builds to be sourced both by build_cron.sh and
# by the build_docker.sh and wheel/build_wheel.sh scripts.

echo "nightly_defaults.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"

# NIGHTLIES_FOLDER
# N.B. this is also defined in cron_start.sh
#   An arbitrary root folder to store all nightlies folders, each of which is a
#   parent level date folder with separate subdirs for logs, wheels, conda
#   packages, etc. This should be kept the same across all scripts called in a
#   cron job, so it only has a default value in the top-most script
#   build_cron.sh to avoid the default values from diverging.
if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    if [[ "$(uname)" == 'Darwin' ]]; then
        export NIGHTLIES_FOLDER='/Users/administrator/nightlies/'
    else
        export NIGHTLIES_FOLDER='/scratch/hellemn/nightlies'
    fi
fi

# NIGHTLIES_DATE
# N.B. this is also defined in cron_start.sh
#   The date in YYYY_mm_dd format that we are building for. If this is not
#   already set, then this will first try to find the date of the nightlies
#   folder that this builder repo exists in; e.g. if this script exists in
#   some_dir/2019_09_04/builder/cron/ then this will be set to 2019_09_04 (must
#   match YYYY_mm_dd). This is for convenience when debugging/uploading past
#   dates, so that you don't have to set NIGHTLIES_DATE yourself. If a date
#   folder cannot be found in that exact location, then this will default to
#   the current date.
if [[ -z "$NIGHTLIES_DATE" ]]; then
    set +e
    _existing_nightlies_date="$(basename $(cd $(dirname $0)/../.. && pwd) | grep -o '[0-9][0-9][0-9][0-9]_[0-9][0-9]_[0-9][0-9]')"
    set -e
    if [[ -n "$_existing_nightlies_date" ]]; then
        export NIGHTLIES_DATE="$_existing_nightlies_date"
    else
        export NIGHTLIES_DATE="$(date +%Y_%m_%d)"
        export NIGHTLIES_DATE_COMPACT="$(date +%Y%m%d)"
    fi
fi
if [[ -z "$NIGHTLIES_DATE_COMPACT" ]]; then
    export NIGHTLIES_DATE_COMPACT="${NIGHTLIES_DATE:0:4}${NIGHTLIES_DATE:5:2}${NIGHTLIES_DATE:8:2}"
fi

# Used in lots of places as the root dir to store all conda/wheel/manywheel
# packages as well as logs for the day
export today="$NIGHTLIES_FOLDER/$NIGHTLIES_DATE"
mkdir -p "$today" || true


##############################################################################
# Add new configuration variables below this line. 'today' should always be
# defined ASAP to avoid weird errors
##############################################################################


# List of people to email when things go wrong. This is passed directly to
# `mail -t`
export NIGHTLIES_EMAIL_LIST='hellemn@fb.com'

# PYTORCH_CREDENTIALS_FILE
#   A bash file that exports credentials needed to upload to aws and anaconda.
#   Needed variables are PYTORCH_ANACONDA_USERNAME, PYTORCH_ANACONDA_PASSWORD,
#   AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY. Or it can just export the AWS
#   keys and then prepend a logged-in conda installation to the path.
if [[ -z "$PYTORCH_CREDENTIALS_FILE" ]]; then
    if [[ "$(uname)" == 'Darwin' ]]; then
        export PYTORCH_CREDENTIALS_FILE='/Users/administrator/nightlies/credentials.sh'
    else
        export PYTORCH_CREDENTIALS_FILE='/private/home/hellemn/nightly_credentials.sh'
    fi
fi

# Location of the temporary miniconda that is downloaded to install conda-build
# and aws to upload finished packages TODO this is messy to install this in
# upload.sh and later use it in upload_logs.sh
CONDA_UPLOADER_INSTALLATION="${today}/miniconda"

# N.B. BUILDER_REPO and BUILDER_BRANCH are both set in cron_start.sh, as that
# is the script that actually clones the builder repo that /this/ script is
# running from.
export NIGHTLIES_BUILDER_ROOT="$(cd $(dirname $0)/.. && pwd)"

# The shared pytorch repo to be used by all builds
export NIGHTLIES_PYTORCH_ROOT="${today}/pytorch"

# PYTORCH_REPO
#   The Github org/user whose fork of Pytorch to check out (git clone
#   https://github.com/<THIS_PART>/pytorch.git). This will always be cloned
#   fresh to build with. Default is 'pytorch'
if [[ -z "$PYTORCH_REPO" ]]; then
    export PYTORCH_REPO='pytorch'
fi

# PYTORCH_BRANCH
#   The branch of Pytorch to checkout for building (git checkout <THIS_PART>).
#   This can either be the name of the branch (e.g. git checkout
#   my_branch_name) or can be a git commit (git checkout 4b2674n...). Default
#   is 'latest', which is a special term that signals to pull the last commit
#   before 0:00 midnight on the NIGHTLIES_DATE
if [[ -z "$PYTORCH_BRANCH" ]]; then
    export PYTORCH_BRANCH='latest'
fi

# Clone the requested pytorch checkout
if [[ ! -d "$NIGHTLIES_PYTORCH_ROOT" ]]; then
    git clone --recursive "https://github.com/${PYTORCH_REPO}/pytorch.git" "$NIGHTLIES_PYTORCH_ROOT"
    pushd "$NIGHTLIES_PYTORCH_ROOT"

    # Switch to the latest commit by 11:59 yesterday
    if [[ "$PYTORCH_BRANCH" == 'latest' ]]; then
        echo "PYTORCH_BRANCH is set to latest so I will find the last commit"
        echo "before 0:00 midnight on $NIGHTLIES_DATE"
        git_date="$(echo $NIGHTLIES_DATE | tr '_' '-')"
        last_commit="$(git log --before $git_date -n 1 | perl -lne 'print $1 if /^commit (\w+)/')"
        echo "Setting PYTORCH_BRANCH to $last_commit since that was the last"
        echo "commit before $NIGHTLIES_DATE"
        export PYTORCH_BRANCH="$last_commit"
    fi
    git checkout "$PYTORCH_BRANCH"
    git submodule update
    popd
fi

# PYTORCH_BUILD_VERSION
#   The actual version string. Used in conda like
#       pytorch-nightly==1.0.0.dev20180908
#   or in manylinux like
#       torch_nightly-1.0.0.dev20180908-cp27-cp27m-linux_x86_64.whl
if [[ -z "$PYTORCH_BUILD_VERSION" ]]; then
    export PYTORCH_BUILD_VERSION="1.0.0.dev$NIGHTLIES_DATE_COMPACT"
fi

# PYTORCH_BUILD_NUMBER
#   This is usually the number 1. If more than one build is uploaded for the
#   same version/date, then this can be incremented to 2,3 etc in which case
#   '.post2' will be appended to the version string of the package. This can
#   be set to '0' only if OVERRIDE_PACKAGE_VERSION is being used to bypass
#   all the version string logic in downstream scripts. Since we use the
#   override below, exporting this shouldn't actually matter.
if [[ -z "$PYTORCH_BUILD_NUMBER" ]]; then
    export PYTORCH_BUILD_NUMBER='1'
fi
if [[ "$PYTORCH_BUILD_NUMBER" -gt 1 ]]; then
    export PYTORCH_BUILD_VERSION="${PYTORCH_BUILD_VERSION}${PYTORCH_BUILD_NUMBER}"
fi

# The nightly builds use their own versioning logic, so we override whatever
# logic is in setup.py or other scripts
export OVERRIDE_PACKAGE_VERSION="$PYTORCH_BUILD_VERSION"

# Build folder for conda builds to use
if [[ -z "$TORCH_CONDA_BUILD_FOLDER" ]]; then
    export TORCH_CONDA_BUILD_FOLDER='pytorch-nightly'
fi

# TORCH_PACKAGE_NAME
#   The name of the package to upload. This should probably be pytorch or
#   pytorch-nightly. N.B. that pip will change all '-' to '_' but conda will
#   not. This is dealt with in downstream scripts.
if [[ -z "$TORCH_PACKAGE_NAME" ]]; then
    export TORCH_PACKAGE_NAME='torch-nightly'
fi

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)
if [[ -z "$PIP_UPLOAD_FOLDER" ]]; then
    export PIP_UPLOAD_FOLDER='nightly/'
fi

# nightlies_package_folder()
#     USAGE: nightlies_package_folder $package_type $cuda_version
#   Function from (package_type, CUDA/cpu ver) -> where packages should be
#   stored. OS does not factor since the folders will be on different machines
#   and won't overlap
#   N.B. PYTORCH_FINAL_PACKAGE_DIR is not a constant, and is not set here. This
#   should be set by build_docker or build_mac according to this function.
nightlies_package_folder () {
    echo "${today}/$1/$2/"
}

# (RUNNING|FAILED|SUCCEEDED)_LOG_DIR
#   Absolute path to folders that store final logs. Initially these folders
#   should be empty. Logs are written out to RUNNING_LOG_DIR. When a build
#   fails, it's log should be moved to FAILED_LOG_DIR, and similarily for
#   succeeded builds.
export RUNNING_LOG_DIR="${today}/logs"
export FAILED_LOG_DIR="${today}/logs/failed"
export SUCCEEDED_LOG_DIR="${today}/logs/succeeded"

# Log s3 directory, must not end in a /
if [[ "$(uname)" == 'Darwin' ]]; then
    export LOGS_S3_DIR="nightly_logs/macos/$NIGHTLIES_DATE"
else
    export LOGS_S3_DIR="nightly_logs/linux/$NIGHTLIES_DATE"
fi
# The location of the binary_sizes dir in s3 is hardcoded into
# upload_binary_sizes.sh

# DAYS_TO_KEEP
#   How many days to keep around for clean.sh. Build folders older than this
#   will be purged at the end of cron jobs. '1' means to keep only the current
#   day. Values less than 1 are not allowed. The default is 5.
if [[ -z "$DAYS_TO_KEEP" ]]; then
    if [[ "$(uname)" == 'Darwin' ]]; then
        # Mac machines have less memory
        export DAYS_TO_KEEP=3
    else
        export DAYS_TO_KEEP=5
    fi
fi
if [[ "$DAYS_TO_KEEP" < '1' ]]; then
    echo "DAYS_TO_KEEP cannot be less than 1."
    echo "A value of 1 means to only keep the build for today"
    exit 1
fi

# PYTORCH_NIGHTLIES_TIMEOUT
#   Timeout in seconds. 
#   When full testing is enabled, condas builds often take up to 2 hours 20
#   minutes, so the default is set to (2 * 60 + 20 + 40 [buffer]) * 60 == 10800
#   seconds.
#   When only smoke testing is enabled, condas builds only take up to about an
#   hour, so the default is set to (60 + 20 [buffer]) * 60 == 4800 seconds. On
#   Mac, they can still take up to 2 hours 20 minutes.
if [[ -z "$PYTORCH_NIGHTLIES_TIMEOUT" ]]; then
    if [[ "$(uname)" == 'Darwin' ]]; then
        export PYTORCH_NIGHTLIES_TIMEOUT=10800
    else
        export PYTORCH_NIGHTLIES_TIMEOUT=4800
    fi
fi

# PORTABLE_TIMEOUT
#   Command/executable of some timeout command. Defined here because the path
#   to the MacOS executable is harcoded to the gtimeout that I installed on my
#   machine with homebrew.
if [[ "$(uname)" == 'Darwin' ]]; then
    # On the Mac timeout was installed through 'brew install coreutils', which
    # prepends a 'g' to all the command names
    export PORTABLE_TIMEOUT='/usr/local/bin/gtimeout'
else
    export PORTABLE_TIMEOUT='timeout'
fi
