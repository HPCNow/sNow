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
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

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
    mount --make-private /run
    stage0=/run/stage-0
    stage0_ro=${stage0}/ro
    stage0_rw=${stage0}/rw
    stage0_rw_upper=${stage0_rw}/upper
    stage0_rw_work=${stage0_rw}/work
    stage0_rootfs=${stage0_rw}/rootfs
    stage1=/run/stage-1
    stage1_ro=${stage1}/ro
    stage1_rw=${stage1}/rw
    stage1_rw_upper=${stage1}/rw/upper
    stage1_rw_work=${stage1}/rw/work
    stage1_rootfs=${stage1}/rw/rootfs

    # Iniciate the network
    info "Setting up network configuration"
    dhclient ${netif}
    sleep 2

    # Create the directories and mount the writable file system based on tmpfs (stateless)
    info "Creating mount point directories"
    mkdir -p ${stage0_ro} ${stage0_rw} ${stage0_rootfs}
    mkdir -p ${stage1_ro} ${stage1_rw} ${stage1_rootfs}
    info "Mounting tmpfs as writable layer"
    mount -n -t tmpfs tmpfs-root ${stage0_rw}
    mount --make-private ${stage0_rw}
    if [ $? != 0 ]; then
        warn "failed to create tmpfs"
        exit 1
    fi
    mkdir -p ${stage0_rw_upper} ${stage0_rw_work}
    mkdir -p ${stage1_rw_upper} ${stage1_rw_work}

    if [ "${overlay_type}" = "squashfs" ]; then
        case "${overlay_protocol}" in
            http|https|ftp|tftp) 
                [ -e /tmp/readonly_rootfs.downloaded ] && exit 0
                info "Fetching ${overlay_rootfs}"
                stage0_rootfs=${stage0_rootfs}/rootfs.squashfs
                curl -s ${overlay_rootfs} -o ${stage0_rootfs}
                if [ $? != 0 ]; then
                	warn "failed to download overlay image: error $?"
                	exit 1
                fi
                > /tmp/readonly_rootfs.downloaded
                #fetch_curl ${overlay_rootfs} ${stage0_rootfs}
                ;;
            beegfs)
                die "Protocol yet not supported: ${overlay_protocol}"
                #mount_beegfs ${overlay_rootfs} ${stage0_rootfs}
                #fetch_beegfs ${overlay_rootfs} ${stage0_rootfs}
                ;;
            lustre)
                die "Protocol yet not supported: ${overlay_protocol}"
                #mount_lustre ${overlay_rootfs} ${stage0_rootfs}
                #fetch_lustre ${overlay_rootfs} ${stage0_rootfs}
                ;;
            nfs)
                info "Mounting NFSROOT read-only"
                file_path="${overlay_server%/*}"
                file_name="${overlay_server##*/}"
                stage0_rootfs=${stage0_rootfs}/${file_name}
                if [ "${overlay_fetch}" = "yes" ]; then
                    mkdir -p ${stage0}/fetch_mount
                    mount -t ${overlay_protocol} -o defaults,ro ${file_path} ${stage0}/fetch_mount
                    if [ $? != 0 ]; then
                        warn "failed to mount NFSROOT read-only image"
                        exit 1
                    fi
                    cp -p ${stage0}/fetch_mount/${file_name} ${stage0_rootfs}
                    umount ${stage0}/fetch_mount
                    rmdir ${stage0}/fetch_mount
                else
                    mount -t ${overlay_protocol} -o defaults,ro ${file_path} ${stage0}/rw/rootfs
                    if [ $? != 0 ]; then
                        warn "failed to mount NFSROOT read-only image"
                        exit 1
                    fi
                fi
                ;;
            torrent)
                die "Protocol yet not supported: ${overlay_protocol}"
                #fetch_torrent ${overlay_rootfs} ${stage0_rootfs}
                ;;
            *)
                die "Protocol not supported: ${overlay_protocol}"
                ;;
        esac
        # Mounting SquashFS image
        if [ -e ${stage0_rootfs} ]; then
            stage0_ro_rootfs_path=${stage0_ro}
            info "Mounting squashfs"
            mount -t squashfs -o ro ${stage0_rootfs} ${stage0_ro}
            mount --make-private ${stage0_ro}
            if [ $? != 0 ]; then
                warn "failed to mount SquashFS image"
                exit 1
            fi
        else
            warn "Image is not available ${stage0_rootfs}"
        fi
    fi

    if [ "${overlay_type}" = "nfs" ]; then
        if [ ! -z "${overlay_server}" ]; then 
            stage0_ro_rootfs_path=${stage0_ro}
            info "Mounting NFSROOT read-only"
            mount -t ${overlay_protocol} -o defaults,ro ${overlay_server} ${stage0_ro}
            mount --make-private ${stage0_ro}
            if [ $? != 0 ]; then
                warn "failed to mount NFSROOT read-only image"
                exit 1
            fi
        else
            die "Required parameter 'overlay_server' is missing" 
        fi
    fi

    if [ "${overlay_type}" = "beegfs" ]; then
        info "Mounting BeeGFS-root read-only"
        stage0_ro=${stage0_ro}/beegfs
        stage0_ro_rootfs_path=${stage0_ro}${overlay_rootfs}
        source /etc/default/beegfs-client
        /opt/beegfs/sbin/beegfs-helperd cfgFile=/etc/beegfs/beegfs-helperd.conf pidFile=/var/run/beegfs-helperd.pid
        modprobe beegfs
        sleep 5
        mkdir -p ${stage0_ro}
        sed -e "s|^connClientPortUDP             = 8004|connClientPortUDP             = 8100|g" /etc/beegfs/beegfs-client.conf > /etc/beegfs/beegfs-client-rootfs.conf
        mount -n -t beegfs beegfs_nodev ${stage0_ro} -ocfgFile=/etc/beegfs/beegfs-client-rootfs.conf,_netdev,ro
        if [ $? != 0 ]; then
            warn "failed to mount BeeGFS root read-only image"
            exit 1
        fi
        sleep 5
        mount --make-private ${stage0_ro}
    fi

    if [ "${overlay_type}" = "lustre" ]; then
        if [ ! -z "${overlay_server}" ]; then 
            stage0_ro_rootfs_path=${stage0_ro}
            info "Mounting Lustre-root read-only"
            modprobe lnet
            modprobe lustre
            mount.lustre -o ro ${overlay_server} ${stage0_ro}
            mount --make-private ${stage0_ro}
            if [ $? != 0 ]; then
                warn "failed to mount Lustre-root read-only image"
                exit 1
            fi
        else
            die "Required parameter 'overlay_server' is missing" 
        fi
    fi

    #mount -t overlay -o lowerdir=${stage0_ro},upperdir=${stage0_rw_upper},workdir=${stage0_rw_work} overlay $newroot
    mount -n -t overlay -o lowerdir=${stage0_ro_rootfs_path},upperdir=${stage0_rw_upper},workdir=${stage0_rw_work} overlay $newroot
    if [ $? != 0 ]; then
        warn "failed to mount OverlayFS root file system"
        exit 1
    fi
    mount --make-private $newroot
    mkdir -p ${newroot}${stage0_ro} ${newroot}${stage0_rw}
    mount --move ${stage0_ro} ${newroot}${stage0_ro} || info "Failed to move ${stage0_ro} to ${newroot}${stage0_ro}"
    mount --move ${stage0_rw} ${newroot}${stage0_rw} || info "Failed to move ${stage0_rw} to ${newroot}${stage0_rw}"
    cp -p /run/initramfs/log/var/log/beegfs-client.log $newroot/var/log/beegfs-client.log
    # Workaround to systemd-machine-id-commit + overlayfs bug: https://github.com/systemd/systemd/issues/729
    ip_addr=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
    hostname=$(host ${ip_addr} | cut -d ' ' -f 5 | sed -r 's/((.*)[^\.])\.?/\1/g' )
    echo $hostname > ${newroot}/etc/hostname
    # maybe required by SuSE - inject new exit_if_exists
    echo '[ -e $NEWROOT/proc ]' > $hookdir/initqueue/overlayfsroot.sh
    # force udevsettle to break
    > $hookdir/initqueue/work
fi
