#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function install_workload_client()
{
    #Slurm Workload Manager
    if [[ -f $SNOW_CONF/system_files/etc/slurm/slurm.conf ]]; then
        ln -sf $SNOW_UTIL/bin/slurm-source.sh /etc/profile.d/slurm.sh
        ln -sf $SNOW_UTIL/bin/slurm-source.csh /etc/profile.d/slurm.csh
        groupadd -g $SLURM_GID slurm
        adduser -u $SLURM_UID -g $SLURM_GID -s /bin/false slurm
        case $1 in
            DEBIAN*)
                pkgs="exim4-daemon-light sssd python hdf5-tools hwloc libcgroup1 libcgroup-dev libgtk2.0-0 libhdf5-8 liblua5.2-0 libtool munge numactl slurm-llnl slurm-client"
                INSTALLER="apt-get -y install"
                apt-get -y update
            ;;
            UBUNTU*)
                pkgs="exim4-daemon-light sssd python hdf5-tools hwloc libcgroup1 libcgroup-dev libgtk2.0-0 libhdf5-8 liblua5.2-0 libtool munge numactl slurm-llnl slurm-client"
                INSTALLER="apt-get -y install"
                apt-get -y update
            ;;
            RHEL*|CentOS*)
                sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux 
                chkconfig iptables off
                pkgs="munge ncurses gtk2 rrdtool libcgroup hwloc lua numactl hdf5 perl-DBI perl-Switch slurm-client slurm-munge"
                INSTALLER="yum -y install"
            ;;
            SLES*)
                pkgs="munge ncurses gtk2 rrdtool libcgroup hwloc lua numactl hdf5 perl-DBI perl-Switch slurm-client slurm-munge"
                INSTALLER="zypper -n install"
            ;;
            OpenSUSE*)
                pkgs="munge ncurses gtk2 rrdtool libcgroup hwloc lua numactl hdf5 perl-DBI perl-Switch slurm-client slurm-munge"
                INSTALLER="zypper -n install"
            ;;
            *)
                echo "This distribution is not supported."
             ;;
        esac
        $INSTALLER $pkgs 
        cp -p $SNOW_CONF/system_files/etc/munge/munge.key /etc/munge/munge.key
        chown -R munge:munge /etc/munge
        chmod 600 /etc/munge/munge.key
        systemctl enable munge.service
        systemctl start munge.service
        cp -pr $SNOW_CONF/system_files/etc/slurm/* /etc/slurm/
        mkdir -p /var/run/slurm /var/spool/slurmd /var/spool/slurm /var/log/slurm
        chown -R slurm:slurm /etc/slurm /var/spool/slurmd /var/spool/slurm /var/log/slurm
        systemctl enable slurmd.service
        systemctl start slurmd.service
    fi
} 1>>$LOGFILE 2>&1

function setup_workload_client()
{
    install_workload_client $OS
} 1>>$LOGFILE 2>&1
