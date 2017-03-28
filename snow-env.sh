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
# Virtualization technology 
# Available options :
# * Default : XEN
# * Experimental : DOCKER and LXD (only Ubuntu)
VIRT_TECH=XEN
# GITHUB / Bitbucket REPO
PRIVATE_GIT_TOKEN=
PRIVATE_GIT_REPO=
# Shares
SNOW_PATH=/sNow
SNOW_HOME=/home
SNOW_SOFT=/sNow/easybuild
SNOW_CONF=/sNow/snow-configspace
SNOW_TOOL=/sNow/snow-tools
# Admin User
sNow_USER=snow
sNow_UID=2000
sNow_GROUP=snow
sNow_GID=2000
# HPCNow User
HPCNow_USER=hpcnow
HPCNow_UID=2001
HPCNow_GROUP=snow
HPCNow_GID=2000
