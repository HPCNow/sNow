#!/bin/sh
# beegfsroot - mounts read only rootfs file system from BeeGFS and 
# thanks to list of files available in /etc/rwtab it allows to modify them using tmpfs
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com> as part of sNow! Cluster manager
# More information available here: http://snow.hpcnow.com
# It's specified with the following syntax:
#   beegfs_rootfs=/path/to/rootfs
#   beegfs_mgmt=beegfs01

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#netif="${1:-eth0}"
netif="$1"
#netroot="$2"
newroot="${3:-/sysroot}"

# Read the settings from the files created by a command-line parsing script from /tmp
[ -r /tmp/beegfs.rootfs ] && read beegfs_rootfs < /tmp/beegfs.rootfs
[ -r /tmp/beegfs.mgmt ] && read beegfs_mgmt < /tmp/beegfs.mgmt

if [ -n "${beegfs_rootfs}" ]; then
    # Define directories to be used for beegfs
    mount_point=/run/beegfs
    # Iniciate the network
    info "Setting up network configuration"
    dhclient ${netif}
    sleep 2
    # Create the directories and mount the writable file system based on tmpfs (stateless)
    info "Creating mount point directories"
    mkdir -p ${mount_point}
    if [ ! -z "${beegfs_mgmt}" ]; then 
        info "Mounting BeeGFS-root read-only"
        source /etc/default/beegfs-client
        /opt/beegfs/sbin/beegfs-helperd cfgFile=/etc/beegfs/beegfs-helperd.conf pidFile=/var/run/beegfs-helperd.pid
        modprobe beegfs
        sleep 5
        mount -n -t beegfs beegfs_nodev ${mount_point} -ocfgFile=/etc/beegfs/beegfs-client.conf,_netdev,ro
        if [ $? != 0 ]; then
            warn "Failed to mount BeeGFS root read-only image"
            exit 1
        fi
        sleep 5
    else
        die "Required parameter 'beegfs_rootfs' is missing" 
    fi
    newroot="${mount_point}${beegfs_rootfs}"
    # maybe required by SuSE - inject new exit_if_exists
    echo '[ -e $NEWROOT/proc ]' > $hookdir/initqueue/beegfsfsroot.sh
    # force udevsettle to break
    > $hookdir/initqueue/work
fi
