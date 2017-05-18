#!/bin/sh
# overlayroot - fetch a OS image or mount the rootfs file system from the network and 
# thanks to overlay allows to write files on tmpfs to turn allow stateless setup
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com> as part of sNow! Cluster manager
# More information available here: http://snow.hpcnow.com
# It's specified with the following syntax:
#   overlay_rootfs=http://server/path/to/file/rootfs.squashfs
#   overlay_type=<squashfs|nfs|lustre|beegfs>
#   overlay_opts=ro

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin

#. /lib/url-lib.sh
#. /lib/nfs-lib.sh
netif="$1"
netroot="$2"
newroot="${3:-/sysroot}"


# Read the settings from the files created by a command-line parsing script from /tmp
[ -r /tmp/overlay.type ] && read overlay_type < /tmp/overlay.type
[ -r /tmp/overlay.opts ] && read overlay_opts < /tmp/overlay.opts
[ -r /tmp/overlay.rootfs ] && read overlay_rootfs < /tmp/overlay.rootfs
[ -r /tmp/overlay.server ] && read overlay_server < /tmp/overlay.server
[ -r /tmp/overlay.protocol ] && read overlay_protocol < /tmp/overlay.protocol

# Define directories to be used for overlayfs
stage1=/run/stage-1
stage1_ro=${stage1}/ro
stage1_rw=${stage1}/rw
stage1_rw_upper=${stage1}/rw/upper
stage1_rw_work=${stage1}/rw/work
stage1_rootfs=${stage1}/rootfs

# Iniciate the network
info "Setting up network configuration"
dhclient ${netif}
sleep 5

# Create the directories and mount the writable file system based on tmpfs (stateless)
info "Creating mount point directories"
mkdir -p ${stage1_ro} ${stage1_rw} ${stage1_rootfs}
info "Mounting tmpfs as writable layer"
mount -t tmpfs tmpfs-root ${stage1_rw}
if [ $? != 0 ]; then
    warn "failed to create tmpfs"
    exit 1
fi
mkdir -p ${stage1_rw_upper} ${stage1_rw_work}

if [ "${overlay_type}" = "squashfs" ]; then
    [ -e /tmp/readonly_rootfs.downloaded ] && exit 0
    info "Fetching ${overlay_rootfs}"
    stage1_rootfs=rootfs.squashfs
    curl -s ${overlay_rootfs} -o /tmp/${stage1_rootfs}
    if [ $? != 0 ]; then
    	warn "failed to download overlay image: error $?"
    	exit 1
    fi
    > /tmp/readonly_rootfs.downloaded
fi

# TODO: couldn't dmsquash-overlay-root handle this?
if [ -e /tmp/${stage1_rootfs} ]; then
    info "Mounting squashfs"
    mount -t squashfs /tmp/${stage1_rootfs} ${stage1_ro}
else
    warn "image not available /tmp/${stage1_rootfs}"
    #nfs_to_var $netroot $netif
    #[ -z "$server" ] && die "Required parameter 'server' is missing"
    #mount_nfs $netroot ${stage1_ro} $netif && { [ -e /dev/root ] || ln -s null /dev/root ; [ -e /dev/nfs ] || ln -s null /dev/nfs; }
    #[ -f $newroot/etc/fstab ] && cat $newroot/etc/fstab > /dev/null
fi

#mount -t overlay -o lowerdir=${stage1_ro},upperdir=${stage1_rw_upper},workdir=${stage1_rw_work} overlay ${stage1_rootfs}
info "Mounting overlayfs: mount -t overlay -o lowerdir=${stage1_ro},upperdir=${stage1_rw_upper},workdir=${stage1_rw_work} overlay $newroot"
mount -t overlay -o lowerdir=${stage1_ro},upperdir=${stage1_rw_upper},workdir=${stage1_rw_work} overlay $newroot
