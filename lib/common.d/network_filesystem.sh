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
function install_nfs_client()
{
    local prefix=$1
    for i in {1..100}; do
        if [[ ! -z ${MOUNT_NFS[$i]} ]]; then
            mkdir -p $(echo "${MOUNT_NFS[$i]}" | gawk '{print $2}')
            echo "${MOUNT_NFS[$i]}" >> ${prefix}/etc/fstab
        fi
    done
} 1>>$LOGFILE 2>&1

function install_beegfs_client()
{
    local prefix=$1
    case $OS in
        debian|ubuntu)
            add_repo http://www.beegfs.com/release/beegfs_${BEEGFS_VERSION}/dists/beegfs-deb${OS_VERSION_MAJOR}.list
            add_repo_key http://www.beegfs.com/release/beegfs_${BEEGFS_VERSION}/gpg/DEB-GPG-KEY-beegfs
            pkgs="beegfs-utils beegfs-opentk-lib beegfs-helperd beegfs-client build-essential linux-kernel-headers linux-headers-$(uname -r)"
        ;;
        rhel|redhat|centos)
            add_repo http://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/dists/beegfs-rhel${OS_VERSION_MAJOR}.repo
            add_repo_key http://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/gpg/RPM-GPG-KEY-beegfs
            pkgs="beegfs-utils beegfs-opentk-lib beegfs-helperd beegfs-client kernel-devel kernel-header"
        ;;
        suse|sle[sd]|opensuse)
            add_repo http://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/dists/beegfs-suse${OS_VERSION_MAJOR}.repo
            add_repo_key http://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/gpg/RPM-GPG-KEY-beegfs
            pkgs="beegfs-utils beegfs-opentk-lib beegfs-helperd beegfs-client"
        ;;
        *)
            warning_msg "This distribution is not supported. BeeGFS client is not going to be installed"
        ;;
    esac
    install_software "$pkgs"
    system_arch=$(uname -m)
    BEEGFS_MGMTD=$(gawk '{if($2 ~ /beegfs-mgmtd/){print $1}}' $SNOW_ROOT/etc/domains.conf)
    if [[ -z ${prefix} ]]; then 
        /opt/beegfs/sbin/beegfs-setup-client -m ${BEEGFS_MGMTD}
        systemctl enable beegfs-helperd.service
        systemctl enable beegfs-client.service
    else
        chroot ${prefix} /opt/beegfs/sbin/beegfs-setup-client -m ${BEEGFS_MGMTD}
        chroot ${prefix} /bin/systemctl enable beegfs-helperd.service
        chroot ${prefix} /bin/systemctl enable beegfs-client.service
    fi
    bkp ${prefix}/etc/beegfs/beegfs-mounts.conf
    rm -f ${prefix}/etc/beegfs/beegfs-mounts.conf
    for i in {1..100}; do
        if [[ ! -z ${MOUNT_BEEGFS[$i]} ]]; then
            mkdir -p $(echo ${MOUNT_BEEGFS[$i]} | gawk '{print $1}')
            echo "${MOUNT_BEEGFS[$i]}" >> ${prefix}/etc/beegfs/beegfs-mounts.conf
        fi
    done
} 1>>$LOGFILE 2>&1

function setup_networkfs()
{
    local prefix=$1
    # Check for NFS mount points in the snow.conf
    NFS_CLIENT=$(gawk 'BEGIN{cfs="FALSE"}{if($1 ~ /^MOUNT_NFS/){cfs="TRUE"}}END{print cfs}' $SNOW_ROOT/etc/snow.conf)
    if [[ "$NFS_CLIENT" == "TRUE" ]]; then
        install_nfs_client $prefix
    fi
    BEEGFS_CLIENT=$(gawk 'BEGIN{cfs="FALSE"}{if($1 ~ /^MOUNT_BEEGFS/){cfs="TRUE"}}END{print cfs}' $SNOW_ROOT/etc/snow.conf)
    if [[ "$BEEGFS_CLIENT" == "TRUE" ]]; then
        install_beegfs_client $prefix
    fi
} 1>>$LOGFILE 2>&1

