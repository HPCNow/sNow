#!/bin/csh
setenv SBATCH_EXPORT NONE
setenv SLURM_CONF /etc/slurm/slurm.conf
alias sq  'squeue -o "%.18i %.9P %.5Q %.8j %.8u %.8T %.10M %.11l %.6D %.4C %.6b %.20S %.20R %.8q"'
alias squ 'squeue -o "%.18i %.9P %.5Q %.8j %.8u %.8T %.10M %.11l %.6D %.4C %.6b %.20S %.20R %.8q" -u $USER'
