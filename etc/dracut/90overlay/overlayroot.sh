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
#netif="${1:-eth0}"
netif="$1"
#netroot="$2"
newroot="${3:-/sysroot}"

# Read the settings from the files created by a command-line parsing script from /tmp
[ -r /tmp/overlay.type ] && read overlay_type < /tmp/overlay.type
[ -r /tmp/overlay.opts ] && read overlay_opts < /tmp/overlay.opts
[ -r /tmp/overlay.rootfs ] && read overlay_rootfs < /tmp/overlay.rootfs
[ -r /tmp/overlay.server ] && read overlay_server < /tmp/overlay.server
[ -r /tmp/overlay.protocol ] && read overlay_protocol < /tmp/overlay.protocol
[ -r /tmp/overlay.fetch ] && read overlay_fetch < /tmp/overlay.fetch

if [ -n "${overlay_rootfs}" ]; then
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
        case "${overlay_protocol}" in
            http|https|ftp|tftp) 
                [ -e /tmp/readonly_rootfs.downloaded ] && exit 0
                info "Fetching ${overlay_rootfs}"
                stage1_rootfs=${stage1_rootfs}/rootfs.squashfs
                curl -s ${overlay_rootfs} -o ${stage1_rootfs}
                if [ $? != 0 ]; then
                	warn "failed to download overlay image: error $?"
                	exit 1
                fi
                > /tmp/readonly_rootfs.downloaded
                #fetch_curl ${overlay_rootfs} ${stage1_rootfs}
                ;;
            beegfs)
                die "Protocol yet not supported: ${overlay_protocol}"
                #mount_beegfs ${overlay_rootfs} ${stage1_rootfs}
                #fetch_beegfs ${overlay_rootfs} ${stage1_rootfs}
                ;;
            lustre)
                die "Protocol yet not supported: ${overlay_protocol}"
                #mount_lustre ${overlay_rootfs} ${stage1_rootfs}
                #fetch_lustre ${overlay_rootfs} ${stage1_rootfs}
                ;;
            nfs)
                info "Mounting NFSROOT read-only"
                file_path="${overlay_server%/*}"
                file_name="${overlay_server##*/}"
                stage1_rootfs=${stage1_rootfs}/${file_name}
                if [ "${overlay_fetch}" = "yes" ]; then
                    mkdir -p ${stage1}/fetch_mount
                    mount -t ${overlay_protocol} -o defaults,ro ${file_path} ${stage1}/fetch_mount
                    if [ $? != 0 ]; then
                        warn "failed to mount NFSROOT read-only image"
                        exit 1
                    fi
                    cp -p ${stage1}/fetch_mount/${file_name} ${stage1_rootfs}
                    umount ${stage1}/fetch_mount
                    rmdir ${stage1}/fetch_mount
                else
                    mount -t ${overlay_protocol} -o defaults,ro ${file_path} ${stage1}/rootfs
                    if [ $? != 0 ]; then
                        warn "failed to mount NFSROOT read-only image"
                        exit 1
                    fi
                fi
                ;;
            torrent)
                die "Protocol yet not supported: ${overlay_protocol}"
                #fetch_torrent ${overlay_rootfs} ${stage1_rootfs}
                ;;
            *)
                die "Protocol not supported: ${overlay_protocol}"
                ;;
        esac
        # Mounting SquashFS image
        if [ -e ${stage1_rootfs} ]; then
            info "Mounting squashfs"
            mount -t squashfs -o ro ${stage1_rootfs} ${stage1_ro}
            if [ $? != 0 ]; then
                warn "failed to mount SquashFS image"
                exit 1
            fi
        else
            warn "Image is not available ${stage1_rootfs}"
        fi
    fi

    if [ "${overlay_type}" = "nfs" ]; then
        if [ ! -z "${overlay_server}" ]; then 
            info "Mounting NFSROOT read-only"
            mount -t ${overlay_protocol} -o defaults,ro ${overlay_server} ${stage1_ro}
            if [ $? != 0 ]; then
                warn "failed to mount NFSROOT read-only image"
                exit 1
            fi
        else
            die "Required parameter 'overlay_server' is missing" 
        fi
    fi

    mount -t overlay -o lowerdir=${stage1_ro},upperdir=${stage1_rw_upper},workdir=${stage1_rw_work} overlay $newroot
    # maybe required by SuSE - inject new exit_if_exists
    echo '[ -e $NEWROOT/proc ]' > $hookdir/initqueue/overlayfsroot.sh
    # force udevsettle to break
    > $hookdir/initqueue/work
fi
