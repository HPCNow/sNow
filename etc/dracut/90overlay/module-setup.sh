#!/bin/bash
# module-setup.sh for overlay

# called by dracut
check()
{
    return 0
}

# called by dracut
depends()
{
    echo network img-lib nfs dm rootfs-block
    return 0
}

installkernel()
{
    #instmods squashfs loop iso9660 overlay nfs beegfs lnet lustre
    instmods squashfs loop iso9660 overlay nfs beegfs
}

# called by dracut
install()
{
    inst /etc/resolv.conf
    inst_multiple umount curl dmsetup blkid dd losetup grep blockdev find tar gzip bzip2 xz bash dirname awk rmmod hostname
    # make this conditional on a cmdline flag / config option
    inst_multiple -o checkisomd5
    # BeeGFS
    inst_multiple -o /etc/beegfs/beegfs-libopentk.conf /etc/beegfs/beegfs-helperd.conf /etc/beegfs/beegfs-client-autobuild.conf /etc/beegfs/beegfs-client.conf /etc/beegfs/beegfs-mounts.conf 
    inst_multiple -o /opt/beegfs/lib/libjbeegfs.so /opt/beegfs/lib/libbeegfs-opentk-disabledIB.so /opt/beegfs/lib/libbeegfs-opentk-enabledIB.so
    inst_multiple -o /sbin/fsck.beegfs /usr/bin/beegfs-check-servers /usr/bin/beegfs-ctl /usr/bin/beegfs-df /usr/bin/beegfs-fsck /usr/bin/beegfs-net
    inst_multiple -o /opt/beegfs/sbin/beegfs-helperd /opt/beegfs/sbin/beegfs-setup-client
    inst_multiple -o /etc/ld.so.conf.d/beegfs.conf /etc/beegfs/lib/init-multi-mode.beegfs-client /etc/default/beegfs-client
    # Lustre
    inst_multiple -o mount.lustre lustre_routes_config lctl
    [ -e /etc/udev/rules.d/95-lustre.rules ] && inst_rules /etc/udev/rules.d/95-lustre.rules
    [ -e /etc/modprobe.d/lnet.conf ] && dracut_install /etc/modprobe.d/lnet.conf
    # OverlayFS
    inst_hook cmdline 90 "$moddir/parse-overlay-opts.sh"
    inst_hook pre-pivot 90 "$moddir/overlayroot.sh"
    # required by SuSE?
    dracut_need_initqueue
}

