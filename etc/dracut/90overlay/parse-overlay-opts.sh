#!/bin/sh
# overlay rootfs images can be squashfs or folder shared by NFS, BeeGFS or Lustre which contains the OS file system. 
# overlayroot - fetch a OS image or mount the rootfs file system from the network and 
# thanks to overlay allows to write files on tmpfs to turn allow stateless setup
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com> as part of sNow! Cluster manager
# More information available here: http://snow.hpcnow.com
# It's specified with the following syntax:
#   overlay_rootfs=http://server/path/to/file/rootfs.squashfs
#   overlay_type=<squashfs|nfs|lustre|beegfs>
#   overlay_opts=ro
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
info "parse overlay triggered - params: $@"

# Get initramfs command-line arguments
overlay_type=$(getarg overlay_type=)
overlay_opts=$(getarg overlay_opts=)
overlay_rootfs=$(getarg overlay_rootfs=)
overlay_server=${overlay_rootfs#*//*}

if getarg ro ; then
    [ -n ${overlay_opts} ] && overlay_opts="${overlay_opts},ro" || overlay_opts="ro"
fi
if getarg rw ; then
    [ -n ${overlay_opts} ] && overlay_opts="${overlay_opts},rw" || overlay_opts="rw"
fi

# Define default values
default_overlay_type=squashfs
default_overlay_opts=ro
overlay_type=${overlay_type:-${default_overlay_type}}
overlay_opts=${overlay_opts:-${default_overlay_opts}}

# Evaluate protocol used
case "${overlay_rootfs}" in
    beegfs://*)
        overlay_protocol=lustre
        ;;
    lustre://*)
        overlay_protocol=lustre
        ;;
    nfs://*)
        overlay_protocol=nfs
        ;;
    http://*) 
        overlay_protocol=http
        ;;
    https://*)
        overlay_protocol=https
        ;;
    ftp://*)
        overlay_protocol=ftp
        ;;
    torrent://*)
        overlay_protocol=torrent
        ;;
    tftp://*)
        overlay_protocol=tftp
        ;;
    *)
        warn "Protocol not supported: ${overlay_rootfs}"
        ;;
esac

# Write the argument values out to temporary files under /tmp
# These will be used later by our overlayroot.sh script to
# mount the overlay fs
[ -n "${overlay_type}" ] && echo ${overlay_type} > /tmp/overlay.type
[ -n "${overlay_opts}" ] && echo ${overlay_opts} > /tmp/overlay.opts
[ -n "${overlay_rootfs}" ] && echo ${overlay_rootfs} > /tmp/overlay.rootfs
[ -n "${overlay_server}" ] && echo ${overlay_server} > /tmp/overlay.server
[ -n "${overlay_protocol}" ] && echo ${overlay_protocol} > /tmp/overlay.protocol

# Set of varialbles required by dracut
rootok=1
root="overlayfs"
netroot=overlayfs


echo '[ -e $NEWROOT/proc ]' > /initqueue-finished/overlayroot.sh
echo '[ -e $NEWROOT/proc ]' > $hookdir/initqueue/finished/overlayroot.sh

