#!/bin/bash
# This script allows to create and update your own local repo into your shared filesystem
# This code is part of the sNow! HPC cluster suite
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
LOCALREPODIR=/sNow/OS/CentOS/7.2/LOCAL
mkdir -p $LOCALREPODIR 
cd $LOCALREPODIR

createrepo $LOCALREPODIR

