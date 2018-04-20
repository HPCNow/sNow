#!/bin/bash
sleep 60
export SLURM_CONF=/etc/slurm/slurm.conf
/usr/bin/sacctmgr -i create cluster __CLUSTER_NAME__
systemctl restart slurmctld
