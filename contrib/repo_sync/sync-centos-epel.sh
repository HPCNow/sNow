#!/bin/bash
# This script allows to syncronise the CentOS EPEL repo into your shared filesystem
# This code is part of the sNow! HPC cluster suite
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

LOCALREPODIR=/sNow/OS/CentOS/7.2/EPEL
mkdir -p $LOCALREPODIR 
cd $LOCALREPODIR

reposync -n -r epel
repomanage -o -c epel | xargs rm -fv
createrepo epel

