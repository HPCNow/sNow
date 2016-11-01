#!/bin/bash
export SLURM_CONF=/etc/slurm/slurm.conf
/usr/bin/sacctmgr -i create cluster __CLUSTER_NAME__
