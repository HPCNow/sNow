#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website: www.hpcnow.com/snow
#
source ${SNOW_ROOT}/snow-tools/share/snow-env.sh

#Example 1: This example creates a raid 0 based on 4 local disks and also formats the raid with xfs
#raid_level="0"
#device="/dev/md0"
#disks="sdb sdc sdd sde"
#mountpoint="/scratch"
#filesystem="xfs"
#mkfs_options="-isize=512 -f"
#mount_options="-onoatime,nodiratime,logbufs=8,logbsize=256k,largeio,inode64,swalloc,allocsize=131072k,nobarrier"

#setup_raid "${raid_level}" "${device}" "${disks}"
#create_filesystem "${mountpoint}" "${filesystem}" "${mkfs_options}" "${mount_options}" "${device}"
#mount "${mountpoint}"

################################################################################################################ 

#Example 2: This example creates a file system with xfs on a dedicated disk for temporary data (local scratch)
device="/dev/sda"
mountpoint="/scratch"
filesystem="xfs"
mkfs_options="-isize=512 -f"
mount_options="-onoatime,nodiratime,logbufs=8,logbsize=256k,largeio,inode64,swalloc,allocsize=131072k,nobarrier"
create_filesystem "${mountpoint}" "${filesystem}" "${mkfs_options}" "${mount_options}" "${device}"
mount "${mountpoint}"
