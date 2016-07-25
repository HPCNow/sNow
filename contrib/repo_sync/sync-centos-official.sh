#!/bin/bash
# This script allows to syncronise the official CentOS base and updates repo into your shared filesystem
# This code is part of the sNow! HPC cluster suite
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

LOCALREPODIR=/sNow/OS/CentOS/7.2/BASE
mkdir -p $LOCALREPODIR 
cd $LOCALREPODIR

reposync -n -r updates
repomanage -o -c updates | xargs rm -fv
createrepo updates

reposync -n -r base --downloadcomps
repomanage -o -c base | xargs rm -fv
createrepo base -g comps.xml
