#!/bin/bash
# This is the sNow! Install Script
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
# sNow cluster (default configuration is only one sNow! master node)
MASTER_HOSTNAME=snow01
SNOW_HOSTNAME_PREFIX=snow
SNOW_COUNT=1
NFS_SERVER=$MASTER_HOSTNAME
