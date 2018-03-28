#!/bin/bash
#
# This file contains the common functions used by sNow! Command Line Interface
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
