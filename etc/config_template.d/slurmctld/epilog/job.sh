#!/bin/bash
#set -xv
# Remove temporary directories for the job
SCRATCH_DIR=/scratch/jobs/$SLURM_JOB_USER/$SLURM_JOBID
SHM_DIR=/dev/shm/jobs/$SLURM_JOB_USER/$SLURM_JOBID
TMP_DIR=/tmp/jobs/$SLURM_JOB_USER/$SLURM_JOBID
rm -rf $SCRATCH_DIR 2>/dev/null >/dev/null
rm -rf $SHM_DIR 2>/dev/null >/dev/null
rm -rf $TMP_DIR 2>/dev/null >/dev/null

#ANSYS Fluent Job Epilog
Filename=$PWD/cleanup-fluent-$HOSTNAME-*.sh
if [ -f $FileName ]; then
    /bin/sh  $FileName
fi
#Star-CCM+ Job Epilog
Filename=/projects/uoa00240/STAR-CCM+9.04.009-R8/star/bin/kill_starccm+
if [ -x $FileName ]; then
    $FileName
fi
exit 0
