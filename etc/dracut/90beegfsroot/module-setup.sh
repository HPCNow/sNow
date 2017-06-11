#!/bin/bash
# module-setup.sh for BeeGFS


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
    instmods beegfs
}

# called by dracut
install()
{
    inst /etc/resolv.conf
    inst_multiple umount blkid grep find bash dirname awk rmmod
    # make this conditional on a cmdline flag / config option
    inst_multiple -o checkisomd5
    # BeeGFS
    inst_multiple -o /etc/beegfs/beegfs-libopentk.conf /etc/beegfs/beegfs-helperd.conf /etc/beegfs/beegfs-client-autobuild.conf /etc/beegfs/beegfs-client.conf /etc/beegfs/beegfs-mounts.conf 
    inst_multiple -o /opt/beegfs/lib/libjbeegfs.so /opt/beegfs/lib/libbeegfs-opentk-disabledIB.so /opt/beegfs/lib/libbeegfs-opentk-enabledIB.so
    inst_multiple -o /sbin/fsck.beegfs /usr/bin/beegfs-check-servers /usr/bin/beegfs-ctl /usr/bin/beegfs-df /usr/bin/beegfs-fsck /usr/bin/beegfs-net
    inst_multiple -o /opt/beegfs/sbin/beegfs-helperd /opt/beegfs/sbin/beegfs-setup-client
    inst_multiple -o /etc/ld.so.conf.d/beegfs.conf /etc/beegfs/lib/init-multi-mode.beegfs-client /etc/default/beegfs-client
    inst_hook cmdline 90 "$moddir/parse-beegfs-opts.sh"
    inst_hook pre-pivot 90 "$moddir/beegfsroot.sh"
    # required by SuSE?
    dracut_need_initqueue
}
