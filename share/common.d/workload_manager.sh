#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

function install_slurm_client()
{
    ln -sf $SNOW_TOOL/bin/slurm-source.sh /etc/profile.d/slurm.sh
    ln -sf $SNOW_TOOL/bin/slurm-source.csh /etc/profile.d/slurm.csh
    groupadd -g $SLURM_GID slurm
    useradd -u $SLURM_UID -g $SLURM_GID -s /bin/false slurm
    case $OS in
        debian|ubuntu)
            pkgs="exim4-daemon-light sssd python hdf5-tools hwloc libcgroup1 libcgroup-dev libgtk2.0-0 libhdf5-8 liblua5.2-0 libtool munge numactl slurm-llnl slurm-client"
        ;;
        rhel|redhat|centos)
            sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux 
            pkgs="munge ncurses gtk2 rrdtool libcgroup hwloc lua numactl hdf5 perl-DBI perl-Switch slurm slurm-devel slurm-lua slurm-munge slurm-pam_slurm slurm-plugins"
        ;;
        suse|sle[sd]|opensuse)
            #add_repo http://download.opensuse.org/repositories/network:/cluster/openSUSE_Leap_42.2/network:cluster.repo
            pkgs="munge ncurses gtk2-devel rrdtool libcgroup hwloc lua numactl hdf5 perl-DBI perl-Switch slurm slurm-devel slurm-lua slurm-munge slurm-pam_slurm slurm-plugins"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
    cp -p $SNOW_CONF/system_files/etc/munge/munge.key /etc/munge/munge.key
    chown -R munge:munge /etc/munge
    chmod 600 /etc/munge/munge.key
    systemctl enable munge.service
    systemctl start munge.service
    mkdir -p /etc/slurm /var/run/slurm /var/spool/slurmd /var/spool/slurm /var/log/slurm
    cp -pr $SNOW_CONF/system_files/etc/slurm/* /etc/slurm/
    chown -R slurm:slurm /etc/slurm /var/spool/slurmd /var/spool/slurm /var/log/slurm
    systemctl enable slurmd.service
    systemctl start slurmd.service
    systemctl disable slurm.service
} 1>>$LOGFILE 2>&1

function install_torque_client()
{
    case $OS in
        debian|ubuntu)
            pkgs="cgroup-tools hwloc libssl-dev libxml2-dev"
        ;;
        rhel|redhat|centos)
            pkgs="libcgroup-tools hwloc openssl-devel libxml2-devel"
        ;;
        suse|sle[sd]|opensuse)
            pkgs="libcgroup-tools libcgroup hwloc numactl libopenssl-devel libxml2-devel"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
    system_arch=$(uname -m)
    /sNow/OS/Linux/${system_arch}/torque/${TORQUE_VERSION}/torque-package-mom-linux-${system_arch}.sh --install
    /sNow/OS/Linux/${system_arch}/torque/${TORQUE_VERSION}/torque-package-clients-linux-${system_arch}.sh --install
    /sNow/OS/Linux/${system_arch}/torque/${TORQUE_VERSION}/torque-package-doc-linux-${system_arch}.sh --install
    /sNow/OS/Linux/${system_arch}/torque/${TORQUE_VERSION}/torque-package-pam-linux-${system_arch}.sh --install
    ldconfig
    cp /sNow/OS/Linux/${system_arch}/torque/${TORQUE_VERSION}/contrib/systemd/pbs_mom.service /usr/lib/systemd/system/
    systemctl enable pbs_mom.service
    systemctl start pbs_mom.service
    cp /sNow/OS/Linux/${system_arch}/torque/${TORQUE_VERSION}/contrib/systemd/trqauthd.service /usr/lib/systemd/system/
    systemctl enable trqauthd.service
    systemctl start trqauthd.service
    SNOW_TORQUE_MASTER=$(gawk '{if($2 ~ /torque-master/){print $1}}' $SNOW_TOOL/etc/domains.conf)
    if  [[ ! -z "$SNOW_TORQUE_MASTER" && ! -z "$SITE_TORQUE_MASTER" ]]; then 
        TORQUE_MASTER=$SNOW_TORQUE_MASTER
    else
        TORQUE_MASTER="${SITE_TORQUE_MASTER:-$SNOW_TORQUE_MASTER}"
    fi
    echo "${TORQUE_MASTER}" > /var/spool/torque/server_name
} 1>>$LOGFILE 2>&1


function setup_workload_client()
{
    # Slurm Workload Manager
    if [[ -f $SNOW_CONF/system_files/etc/slurm/slurm.conf ]]; then
        install_slurm_client
    fi
    # Torque Workload Manager
    if  [[ ! -z "${TORQUE_VERSION}" ]]; then
        install_torque_client
    fi
}

