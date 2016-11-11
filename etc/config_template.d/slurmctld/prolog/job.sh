#!/bin/bash
# Create directories for job profiling
PROFDIR=/scratch/profiling/$SLURM_JOB_USER
if [ ! -d "$PROFDIR" ]; then
    mkdir -p $PROFDIR
    chown $SLURM_JOB_USER $PROFDIR
    chmod 700 $PROFDIR
fi

# Create directories for job checkpointing
CHK_DIR=/scratch/checkpoint/$SLURM_JOB_USER
if [ ! -d "$CHK_DIR" ]; then
    mkdir -p $CHK_DIR
    chown $SLURM_JOB_USER $CHK_DIR
    chmod 700 $CHK_DIR
fi

# Create temporary directories for the job
for DIRECTORY in /scratch/jobs/$SLURM_JOB_USER /dev/shm/jobs/$SLURM_JOB_USER /tmp/jobs/$SLURM_JOB_USER 
do
  if [ ! -d "$DIRECTORY" ]; then
      mkdir -p $DIRECTORY
      chown $SLURM_JOB_USER $DIRECTORY
      chmod 700 $DIRECTORY
  fi
  TDIRECTORY=$DIRECTORY/$SLURM_JOBID
  if [ ! -d "$TDIRECTORY" ]; then
      mkdir -p $TDIRECTORY
      chown $SLURM_JOB_USER $TDIRECTORY
      chmod 700 $TDIRECTORY
  fi 
done

#exit 0
