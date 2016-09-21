#!/bin/bash
# Create temporary directories for the job

echo "export SHM_DIR=/dev/shm/jobs/$SLURM_JOB_USER/$SLURM_JOBID"
echo "export TMP_DIR=/tmp/jobs/$SLURM_JOB_USER/$SLURM_JOBID"
echo "export TMPDIR=/tmp/jobs/$SLURM_JOB_USER/$SLURM_JOBID"
echo "export SCRATCH_DIR=/scratch/jobs/$SLURM_JOB_USER/$SLURM_JOBID"
echo "export CHK_DIR=/scratch/checkpoint/$SLURM_JOB_USER"

echo "export TMOUT=300"

if [ $SLURM_CPUS_PER_TASK -ge 1 ]; then
    echo "export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK"
fi

exit 0
