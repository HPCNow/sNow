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
# overlay rootfs images can be squashfs or folder shared by NFS, BeeGFS or Lustre which contains the OS file system. 
# overlayroot - fetch a OS image or mount the rootfs file system from the network and 
# thanks to overlay allows to write files on tmpfs to turn allow stateless setup
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
overlay_fetch=$(getarg overlay_fetch=)
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
default_overlay_fetch=yes
overlay_type=${overlay_type:-${default_overlay_type}}
overlay_opts=${overlay_opts:-${default_overlay_opts}}
overlay_fetch=${overlay_fetch:-${default_overlay_fetch}}

# Evaluate protocol used
if [ "${overlay_type}" = "squashfs" ]; then
    case "${overlay_rootfs}" in
        beegfs://*)
            overlay_protocol=beegfs
            ;;
        lustre://*)
            overlay_protocol=lustre
            ;;
        nfs://*)
            overlay_protocol=nfs
            ;;
        nfsv4://*)
            overlay_protocol=nfsv4
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
fi

if [ -n "${overlay_rootfs}" ]; then
    # Write the argument values out to temporary files under /tmp
    # These will be used later by our overlayroot.sh script to  mount the overlay fs
    [ -n "${overlay_type}" ] && echo ${overlay_type} > /tmp/overlay.type
    [ -n "${overlay_opts}" ] && echo ${overlay_opts} > /tmp/overlay.opts
    [ -n "${overlay_rootfs}" ] && echo ${overlay_rootfs} > /tmp/overlay.rootfs
    [ -n "${overlay_server}" ] && echo ${overlay_server} > /tmp/overlay.server
    [ -n "${overlay_protocol}" ] && echo ${overlay_protocol} > /tmp/overlay.protocol
    [ -n "${overlay_fetch}" ] && echo ${overlay_fetch} > /tmp/overlay.fetch
    # Set of varialbles required by dracut
    rootok=1
    root="overlayfs"
    #netroot=overlayfs

    # RHEL/CentOS
    if [ -e /initqueue-finished ]; then
        echo '[ -e $NEWROOT/proc ]' > /initqueue-finished/overlayroot.sh
    fi
    # SuSE
    if [ -e $hookdir/initqueue/finished ]; then
        [ -e /dev/root ] || ln -s null /dev/root
        echo '[ -e /dev/root ]' > $hookdir/initqueue/finished/overlayroot.sh
    fi
fi
