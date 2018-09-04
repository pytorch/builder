BATCH --job-name=pytorch_binary_nightly_build
## filename for job standard output (stdout)
## %j is the job id, %u is the user id
#SBATCH --output=/checkpoint/%u/jobs/pytorch_binary_nightly_build_%j.out
## filename for job standard error output (stderr)
#SBATCH --error=/checkpoint/%u/jobs/pytorch_binary_nightly_build_%j.err

## partition name
#SBATCH --partition=uninterrupted

## We need 36 jobs. (cpu + 3*CUDA) * (4 conda_py + 5 pip_py)
## We want 8 cpus per task to compile in parallel quickly
## Each node contains 40 CPU cores which is 80 threads
## We can fit 5 tasks per node, so we need 10 nodes

#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-node=5
#SBATCH --nodes=10

#SBATCH --mail-user=hellemn@fb.com
#SBATCH --mail-type=end


### Global environment variables

# Vars needed for prep_nightly.sh
export PYTORCH_REPO'




### Section 3:
### Run your job. Note that we are not passing any additional
### arguments to srun since we have already specificed the job
### configuration with SBATCH directives
_### This is going to run ntasks-per-node x nodes tasks with each
_### task seeing all the GPUs on each node. However I am using
### the wrapper.sh example I showed before so that each task only
### sees one GPU
srun --label slurm_nightlies.sh
