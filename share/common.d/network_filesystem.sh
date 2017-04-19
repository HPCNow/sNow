#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

function setup_networkfs()
{
    local prefix=$1
    # Check for NFS mount points in the snow.conf
    NFS_CLIENT=$(gawk 'BEGIN{cfs="FALSE"}{if($1 ~ /^MOUNT_NFS/){cfs="TRUE"}}END{print cfs}' $SNOW_TOOL/etc/snow.conf)
    if [[ "$NFS_CLIENT" == "TRUE" ]]; then
        for i in {1..100}; do
            if [[ ! -z ${MOUNT_NFS[$i]} ]]; then
                mkdir -p $(echo "${MOUNT_NFS[$i]}" | gawk '{print $2}')
                echo "${MOUNT_NFS[$i]}" >> ${prefix}/etc/fstab
            fi
        done
    fi
} 1>>$LOGFILE 2>&1
