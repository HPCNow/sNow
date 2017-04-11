#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website: www.hpcnow.com/snow
#
setup_raid()
{
    local raid_level="$1"
    local device="$2"
    local disks="$3"
	local partitions=""
    local ndevices=$(echo $disks | wc -w)
    # Create raid partition type in each disk
    for disk in ${disks}; do
        fdisk /dev/$disk << EOF
n
p
1


t
fd
w
EOF
        partprobe /dev/${disk}
        partitions="$partitions /dev/${disk}1"
	done
    # Create RAID volume
    if [ -n "$partitions" ]; then
        mdadm --create ${device} --level ${raid_level} --raid-devices ${ndevices} $partitions
    fi
}

create_filesystem()
{
    local mountpoint="$1"
    local filesystem="$2"
    local mkfs_options="$3"
    local mount_options="$4"
    local device="$5"
	mkfs -t ${filesystem} ${mkfs_options} ${device}
    replace_text "/etc/fstab" "${device}" "${device} $mountpoint ${filesystem} ${mount_options}    0 0"
    mkdir -p $mountpoint
}
