#!/bin/sh
# beegfsroot - mounts read only rootfs file system from BeeGFS and 
# thanks to list of files available in /etc/rwtab it allows to modify them using tmpfs
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com> as part of sNow! Cluster manager
# More information available here: http://snow.hpcnow.com
# It's specified with the following syntax:
#   beegfs_rootfs=/path/to/rootfs
#   beegfs_mgmt=beegfs01
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

# Get initramfs command-line arguments
beegfs_rootfs=$(getarg beegfs_rootfs=)
#beegfs_mgmt=${beegfs_rootfs#*//*}
beegfs_mgmt=$(getarg beegfs_mgmt=)

if [ -n "${beegfs_rootfs}" ]; then
    # Write the argument values out to temporary files under /tmp
    # These will be used later by our beegfsroot.sh script to  mount the beegfs fs
    [ -n "${beegfs_rootfs}" ] && echo ${beegfs_rootfs} > /tmp/beegfs.rootfs
    [ -n "${beegfs_mgmt}" ] && echo ${beegfs_mgmt} > /tmp/beegfs.mgmt
    # Set of varialbles required by dracut
    rootok=1
    root="beegfs"
    #netroot=beegfs

    # RHEL/CentOS
    if [ -e /initqueue-finished ]; then
        echo '[ -e $NEWROOT/proc ]' > /initqueue-finished/beegfsroot.sh
    fi
    # SuSE
    if [ -e $hookdir/initqueue/finished ]; then
        [ -e /dev/root ] || ln -s null /dev/root
        echo '[ -e /dev/root ]' > $hookdir/initqueue/finished/beegfsroot.sh
    fi
fi
