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
    #echo network url-lib img-lib nfs
    echo network img-lib nfs dm rootfs-block
    return 0
}

installkernel()
{
    instmods squashfs loop iso9660 overlay nfs
}

# called by dracut
install()
{
    inst_multiple umount curl dmsetup blkid dd losetup grep blockdev find tar gzip bzip2 xz bash
    # make this conditional on a cmdline flag / config option
    inst_multiple -o checkisomd5
    inst_hook cmdline 90 "$moddir/parse-overlay-opts.sh"
    #inst_dir /overlaymnt
    #if dracut_module_included "systemd-initrd"; then
    #    inst_script "$moddir/overlay-generator.sh" $systemdutildir/system-generators/dracut-overlay-generator
    #fi
    inst_hook pre-pivot 90 "$moddir/overlayroot.sh"
    # requires by SuSE?
    dracut_need_initqueue
}
