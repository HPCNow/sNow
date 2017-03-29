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

function setup_workload_client()
{
    #Slurm Workload Manager
    if [[ -f $SNOW_CONF/system_files/etc/slurm/slurm.conf ]]; then
        install_slurm_client
    fi
}

