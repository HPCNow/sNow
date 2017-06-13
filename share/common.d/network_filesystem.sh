#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
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
            add_repo http://www.beegfs.com/release/beegfs_${BEEGFS_VERSION}/dists/beegfs-deb8.list
            add_repo_key http://www.beegfs.com/release/beegfs_${BEEGFS_VERSION}/gpg/DEB-GPG-KEY-beegfs
            pkgs="beegfs-utils beegfs-opentk-lib beegfs-helperd beegfs-client build-essential linux-kernel-headers linux-headers-$(uname -r)"
        ;;
        rhel|redhat|centos)
            add_repo http://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/dists/beegfs-rhel7.repo
            add_repo_key http://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/gpg/RPM-GPG-KEY-beegfs
            pkgs="beegfs-utils beegfs-opentk-lib beegfs-helperd beegfs-client kernel-devel kernel-header"
        ;;
        suse|sle[sd]|opensuse)
            add_repo http://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/dists/beegfs-suse12.repo
            add_repo_key http://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/gpg/RPM-GPG-KEY-beegfs
            pkgs="beegfs-utils beegfs-opentk-lib beegfs-helperd beegfs-client"
        ;;
        *)
            warning_msg "This distribution is not supported. BeeGFS client is not going to be installed"
        ;;
    esac
    install_software "$pkgs"
    system_arch=$(uname -m)
    BEEGFS_MGMTD=$(gawk '{if($2 ~ /beegfs-mgmtd/){print $1}}' $SNOW_TOOL/etc/domains.conf)
    if [[ -z ${prefix} ]]; then 
        /opt/beegfs/sbin/beegfs-setup-client -m ${BEEGFS_MGMTD}
        systemctl enable beegfs-helperd.service
        systemctl enable beegfs-client.service
    else
        chroot ${prefix} /opt/beegfs/sbin/beegfs-setup-client -m ${BEEGFS_MGMTD}
        chroot ${prefix} /bin/systemctl enable beegfs-helperd.service
        chroot ${prefix} /bin/systemctl enable beegfs-client.service
    fi
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
    NFS_CLIENT=$(gawk 'BEGIN{cfs="FALSE"}{if($1 ~ /^MOUNT_NFS/){cfs="TRUE"}}END{print cfs}' $SNOW_TOOL/etc/snow.conf)
    if [[ "$NFS_CLIENT" == "TRUE" ]]; then
        install_nfs_client $prefix
    fi
    BEEGFS_CLIENT=$(gawk 'BEGIN{cfs="FALSE"}{if($1 ~ /^MOUNT_BEEGFS/){cfs="TRUE"}}END{print cfs}' $SNOW_TOOL/etc/snow.conf)
    if [[ "$BEEGFS_CLIENT" == "TRUE" ]]; then
        install_beegfs_client $prefix
    fi
} 1>>$LOGFILE 2>&1

