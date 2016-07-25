#!/bin/bash
# This script is part of sNow! Tools
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

# Install the domain
if [[ -z "$GPFS_PRIMARY_SERVER" ]]; then
    /usr/lpp/mmfs/bin/mmsdrrestore -p ${GPFS_PRIMARY_SERVER} -R /usr/bin/scp
fi

