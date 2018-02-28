#!/bin/sh
# This file contains dracut recipies to generage Single System Image in sNow! cluster manager
# Copyright (C) 2008 Jordi Blasco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# sNow! Cluster Suite is an opensource project developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website: www.hpcnow.com/snow
#
# beegfsroot - mounts read only rootfs file system from BeeGFS and 
# thanks to list of files available in /etc/rwtab it allows to modify them using tmpfs
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
    info "Mounting BeeGFS-root read-only"
    source /etc/default/beegfs-client
    /opt/beegfs/sbin/beegfs-helperd cfgFile=/etc/beegfs/beegfs-helperd.conf pidFile=/var/run/beegfs-helperd.pid
    modprobe beegfs
    sleep 5
    sed -e "s|^connClientPortUDP             = 8004|connClientPortUDP             = 8100|g" /etc/beegfs/beegfs-client.conf > /etc/beegfs/beegfs-client-rootfs.conf
    mount -n -t beegfs beegfs_nodev ${mount_point} -ocfgFile=/etc/beegfs/beegfs-client-rootfs.conf,_netdev,ro
    if [ $? != 0 ]; then
        warn "Failed to mount BeeGFS root read-only image"
        exit 1
    fi
    sleep 5
    newroot="${mount_point}${beegfs_rootfs}"
    mount -o bind ${newroot} /sysroot
    # maybe required by SuSE - inject new exit_if_exists
    echo '[ -e $NEWROOT/proc ]' > $hookdir/initqueue/beegfsfsroot.sh
    # force udevsettle to break
    > $hookdir/initqueue/work
#else
#    die "Required parameter 'beegfs_rootfs' is missing" 
fi
