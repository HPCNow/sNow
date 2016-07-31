#!/bin/bash
# This is the sNow! deployment Post Install Script
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow

#set -xv

# sNow! paths
# SNOW_HOME and SNOW_SOFT can be setup in different paths
SNOW_PATH=/sNow
SNOW_HOME=$SNOW_PATH/home
SNOW_SOFT=$SNOW_PATH/easybuild
SNOW_CONF=$SNOW_PATH/snow-configspace
SNOW_UTIL=$SNOW_PATH/snow-utils
SNOW_TOOL=$SNOW_PATH/snow-tools

if [[ -f /sNow/snow-tools/etc/snow.conf ]]; then
    echo "Loading sNow! configuration ..."
    source /sNow/snow-tools/etc/snow.conf
else
    echo "sNow! config file NOT found!!!"
fi

export TEMPLATE=${1:-$DEFAULT_TEMPLATE}

if [[ -f /sNow/snow-configspace/deploy/postconfig.d/$TEMPLATE/config ]]; then
    echo "Loading $TEMPLATE configuration ..."
    source /sNow/snow-configspace/deploy/postconfig.d/$TEMPLATE/config
else
    echo "Config file not found"
fi

LOGFILE=/root/post-install.log
RETAIN_NUM_LINES=10
LAST_WORKER_INDEX=$(($WORKER_COUNT - 1))

# OS release and Service pack discovery 
if [ -f /etc/SuSE-release ]; then
    export OS="SLES"
    export OSVERSION=$(cat /etc/SuSE-release | grep VERSION | cut -f2 -d '=' | sed 's/ //')
    export OSSP=$(/etc/SuSE-release | grep PATCHLEVEL | cut -f2 -d '=' | sed 's/ //')
elif [ -f /etc/fedora-release ]; then
    export OS="FEDORA"
    export OSVERSION=$(cat /etc/fedora-release | sed 's/^.* release \([^\.][^\.]\).*$/\1/')
    export OSSP=""
elif [ -f /etc/redhat-release ]; then
    export OS="RHEL"
    export OSVERSION=$(cat /etc/redhat-release | sed 's/^.* release \([^\.]\).*$/\1/')
    export OSSP=""
elif [ -f /etc/debian_version ]; then
    if [ -f /etc/lsb-release ]; then  
        if [ "z$(grep DISTRIB_ID /etc/lsb-release | cut -f2 -d '=' | sed 's/ //')" = "zUbuntu" ]; then
            export OS="UBUNTU"
            export OSVERSION=$(cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d '=' | sed 's/ //')
            export OSSP=""
        fi
    else
        export OS="DEBIAN"
        export OSVERSION=$(cat /etc/debian_version | cut -f1 -d '.')
        export OSSP=$(cat /etc/debian_version | cut -f2 -d '.')
    fi
elif [ -f /etc/system-release ]; then
    if [ "$(awk -F: '{print $3}' /etc/system-release-cpe)" = "amazon" ]; then
        export OS="AMI"
        export OSVERSION=$(awk -F: '{print $5}' /etc/system-release-cpe)
        export OSSP=""
    fi
else
    export OS="unknown"
fi


function logsetup {
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
}

#logsetup
        
function log {
    echo "[$(date)]: $*" 
}

spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "[\e[0;32m%c\e[m] %s" "$spinstr" "$2" 
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" 
    done
}

error_check()
{
    local status=$1
    printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" 
    if [ $status -eq 0 ]; then
        printf "[\e[0;32m%c\e[m] %s \e[0;32m%s\e[m \n" "*" "$2" "OK"
    else
        printf "[\e[0;31m%c\e[m] %s \e[0;31m%s\e[m \n" "!" "$2" "FAIL"
    fi
}
        


# Returns 0 if this node is a golden node
is_golden_node()
{
    gn=1
    for i in "${GOLDEN_NODES[@]}"
    do
        if [[ "$(hostname -s)" == "$i" ]]; then 
            gn=0
        fi
    done
    return $gn
} 1>>$LOGFILE 2>&1

add_repo()
{
    case $1 in
        Debian*)
            wget -P /etc/apt/sources.list.d/ $2 
        ;;
        Ubuntu*)
            wget -P /etc/apt/sources.list.d/ $2 
        ;;
        RHEL*|CentOS*)
            yum-config-manager --add-repo $2
       ;;
       SLES*|OpenSUSE*)
            zypper --gpg-auto-import-keys ar $2 
       ;;
   esac
}

add_repos()
{
    for REPO in $(cat /sNow/snow-configspace/deploy/postconfig.d/$TEMPLATE/repos); do
        if [[ ! -z ${!REPO} ]]; then
            add_repo $1 $REPO
        fi
    done
}


install_software()
{
    PKG_LIST=/sNow/snow-configspace/deploy/postconfig.d/$TEMPLATE/packages
    pkgs=$(cat $PKG_LIST | grep -v "^#" | tr '\n' ' ')
    add_repos $1
    case $1 in
        DEBIAN*)
            INSTALLER="apt-get -y install"
            apt-get -y update
        ;;
        UBUNTU*)
            INSTALLER="apt-get -y install"
            apt-get -y update
        ;;
        RHEL*|CentOS*)
            INSTALLER="yum -y install"
       ;;
       SLES*)
            INSTALLER="zypper -n install"
       ;;
       OpenSUSE*)
            INSTALLER="zypper -n install"
       ;;
       *)
           echo "This distribution is not supported."
       ;;
   esac
   $INSTALLER $pkgs 
} 1>>$LOGFILE 2>&1


setup_software()
{
    install_software $OS
    #install_packages $OS
} 1>>$LOGFILE 2>&1

setup_networkfs()
{
    # Check for NFS mount points in the snow.conf
    NFS_CLIENT=$(gawk 'BEGIN{cfs="FALSE"}{if($1 ~ /^MOUNT_NFS/){cfs="TRUE"}}END{print cfs}' $SNOW_TOOL/etc/snow.conf)
    if [[ "$NFS_CLIENT" == "TRUE" ]]; then
        for i in {1..100}; do
            if [[ ! -z ${MOUNT_NFS[$i]} ]]; then
                mkdir -p $(echo "${MOUNT_NFS[$i]}" | gawk '{print $2}')
                echo "${MOUNT_NFS[$i]}" >> /etc/fstab
            fi
        done
    fi
} 1>>$LOGFILE 2>&1

setup_snow_user()
{
    # Check UIDs and GIDs
    if [[ -z $(getent passwd $sNow_USER) ]]; then
        groupadd -g $sNow_GID $sNow_GROUP
        useradd -u $sNow_UID -g $sNow_GID -c "sNow! Admin User" -s /bin/bash -d $SNOW_HOME/$sNow_USER  $sNow_USER 
    elif [[ "$(id -u $sNow_USER)" != "$sNow_UID"  &&  "$(id -g $sNow_USER)" != "$sNow_GID" ]]; then
        groupmod -g $sNow_GID $sNow_GROUP
        usermod -u $sNow_UID -g $sNow_GID $sNow_USER
        usermod -c "sNow! Admin User" -g $sNow_GID -d $SNOW_HOME/$sNow_USER -s /bin/bash -m -u $sNow_UID $sNow_USER
    fi
    # Don't require password for sNow! Admin user sudo
    echo "$sNow_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    if is_golden_node; then
        # Configure public key auth for the sNow! Admin User
        mkdir -p $SNOW_HOME/$sNow_USER/.ssh
        # Setup the ACLs to the right user
        chown -R $sNow_USER:$sNow_GROUP $SNOW_HOME/$sNow_USER
    fi
} 1>>$LOGFILE 2>&1

setup_hpcnow_user()
{
    # Check UIDs and GIDs
    if [[ -z $(getent passwd $HPCNow_USER) ]]; then
        useradd -u $HPCNow_UID -g $HPCNow_GID -c "HPCNow! User" -s /bin/bash -d $SNOW_HOME/$HPCNow_USER  $HPCNow_USER 
    elif [[ "$(id -u $HPCNow_USER)" != "$HPCNow_UID"  &&  "$(id -g $HPCNow_USER)" != "$HPCNow_GID" ]]; then
        usermod -c "HPCNow! User" -g $HPCNow_GID -d $SNOW_HOME/$HPCNow_USER -s /bin/bash -m -u $HPCNow_UID $HPCNow_USER
    fi
    # Don't require password for sNow! Admin user sudo
    echo "$HPCNow_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
} 1>>$LOGFILE 2>&1


setup_ssh()
{
    setup_snow_user
    if [[ "$HPCNow_Support" != "none" ]]; then
        setup_hpcnow_user
    fi
    mkdir -p /root/.ssh
    cp -p $SNOW_HOME/$sNow_USER/.ssh/authorized_keys /root/.ssh/authorized_keys
    # Allow support for GPFS requirements
    cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub
    cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa /root/.ssh/id_rsa
    chown -R root:root /root/.ssh
    chmod 700 /root/.ssh
    chmod 640 /root/.ssh/authorized_keys
    cp -pr $SNOW_CONF/system_files/etc/ssh/ssh_host_* /etc/ssh/
    cp -p $SNOW_CONF/system_files/etc/ssh/shosts.equiv /etc/ssh/
    cp -p $SNOW_CONF/system_files/etc/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts
    chmod u+s /usr/lib64/ssh/ssh-keysign
    cp -p /etc/ssh/shosts.equiv /root/.shosts
    sed -i "s/RhostsRSAAuthentication no/RhostsRSAAuthentication yes/g" /etc/ssh/sshd_config
    sed -i "s/HostbasedAuthentication no/HostbasedAuthentication yes/g" /etc/ssh/sshd_config
    sed -i "s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g" /etc/ssh/ssh_config
    echo "GSSAPIAuthentication yes" >> /etc/ssh/sshd_config
    echo "GSSAPICleanupCredentials yes" >> /etc/ssh/sshd_config
    echo "HostbasedUsesNameFromPacketOnly yes" >> /etc/ssh/sshd_config
    echo "IgnoreRhosts no" >> /etc/ssh/sshd_config
    echo "HostbasedUsesNameFromPacketOnly yes" >> /etc/ssh/sshd_config
    echo "UseDNS no" >> /etc/ssh/sshd_config
    systemctl restart sshd
} 1>>$LOGFILE 2>&1

setup_env()
{
    # Set unlimited mem lock
    echo "* hard memlock unlimited" >> /etc/security/limits.conf
    echo "* soft memlock unlimited" >> /etc/security/limits.conf
    # User enviroment setup
    ln -sf $SNOW_UTIL/bin/slurm-source.sh /etc/profile.d/slurm.sh
    ln -sf $SNOW_UTIL/bin/slurm-source.csh /etc/profile.d/slurm.csh
    ln -sf $SNOW_UTIL/bin/easybuild-source.sh /etc/profile.d/easybuild.sh
    #ln -sf $SNOW_UTIL/bin/easybuild-source.csh /etc/profile.d/easybuild.csh
    #ln -sf $SNOW_UTIL/bin/snow-source.sh /etc/profile.d/snow.sh
    #ln -sf $SNOW_UTIL/bin/snow-source.csh /etc/profile.d/snow.csh
} 1>>$LOGFILE 2>&1

install_lmod()
{
    ln -sf $SNOW_UTIL/lmod/lmod/init/profile /etc/profile.d/lmod.sh
    ln -sf $SNOW_UTIL/lmod/lmod/init/cshrc /etc/profile.d/lmod.csh
    if is_golden_node; then
        if [[ ! -e $SNOW_UTIL/lmod/lmod/init/profile ]]; then
            chown -R $sNow_USER:$sNow_GROUP $SNOW_UTIL
            cd $SNOW_UTIL
            su $sNow_USER -c "git clone https://github.com/TACC/Lmod.git /tmp/Lmod; cd /tmp/Lmod; ./configure --prefix=$SNOW_UTIL; make; make install"
        fi
    fi
} 1>>$LOGFILE 2>&1

install_easybuild()
{
    ln -sf $SNOW_UTIL/bin/easybuild-source.sh /etc/profile.d/easybuild.sh
    #ln -sf $SNOW_UTIL/bin/easybuild-source.csh /etc/profile.d/easybuild.csh
    ln -sf $SNOW_UTIL/etc/cpu-id-map.conf /etc/
    if is_golden_node; then
        if [[ ! -e $SNOW_SOFT/modules/all ]]; then
            chown -R $sNow_USER:$sNow_GROUP $SNOW_SOFT
            cd $SNOW_SOFT
            curl -O https://raw.githubusercontent.com/hpcugent/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py
            su - $sNow_USER -c "python $SNOW_SOFT/bootstrap_eb.py $SNOW_SOFT"
        fi
    fi
} 1>>$LOGFILE 2>&1

setup_ldap_client()
{
    if [[ -f $SNOW_CONF/system_files/etc/sssd/sssd.conf.cn ]]; then
        cp -p $SNOW_CONF/system_files/etc/sssd/sssd.conf.cn /etc/sssd/sssd.conf
        chown root:root /etc/sssd/sssd.conf
        chmod 600 /etc/sssd/sssd.conf
        systemctl enable sssd.service
        systemctl start sssd.service
    fi
} 1>>$LOGFILE 2>&1

setup_ganglia_client()
{
    if [[ -f $SNOW_CONF/system_files/etc/ganglia/gmond.conf ]]; then
        cp -p $SNOW_CONF/system_files/etc/ganglia/gmond.conf /etc/ganglia/gmond.conf
        chown root:root /etc/ganglia/gmond.conf
        chmod 640 /etc/ganglia/gmond.conf
        systemctl enable gmond.service
        systemctl start gmond.service
    fi
} 1>>$LOGFILE 2>&1

install_workload_client()
{
    #Slurm Workload Manager
    if [[ -f $SNOW_CONF/system_files/etc/slurm/slurm.conf ]]; then
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
                pkgs="munge ncurses gtk2 rrdtool libcgroup hwloc lua numactl hdf5 perl-DBI perl-Switch slurm-client"
                INSTALLER="yum -y install"
            ;;
            SLES*)
                pkgs="munge ncurses gtk2 rrdtool libcgroup hwloc lua numactl hdf5 perl-DBI perl-Switch slurm-client"
                INSTALLER="zypper -n install"
            ;;
            OpenSUSE*)
                pkgs="munge ncurses gtk2 rrdtool libcgroup hwloc lua numactl hdf5 perl-DBI perl-Switch slurm-client"
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

install_workload_client()
{
    install_workload_client $OS
} 1>>$LOGFILE 2>&1

hooks()
{
    HOOKS=$(ls -1 /sNow/snow-configspace/deploy/postconfig.d/$TEMPLATE/??-*.sh)
    for hook in $HOOKS
    do
        if [[ -x "$hook" ]]; then
            $hook && error_check 0 'Running hook : $hook ' || error_check 1 'Running hook error : $hook ' &
            spinner $!             'Running hook : $hook '
        else
            echo "File '$hook' is not executable. If you want to run it, do : chmod 750 $hook"
        fi
    done
} 

first_boot_hooks()
{
    cp -p /sNow/snow-configspace/deploy/postconfig.d/$TEMPLATE/first_boot/first_boot.service  /lib/systemd/system/
    cp -p /sNow/snow-configspace/deploy/postconfig.d/$TEMPLATE/first_boot/first_boot /usr/local/bin/first_boot
    chmod 700 /usr/local/bin/first_boot
    systemctl enable first_boot
} 1>>$LOGFILE 2>&1

end_msg(){
    echo "--------------------------------------------------------------------------"
    echo "

    ███████╗███╗   ██╗ ██████╗ ██╗    ██╗██╗
    ██╔════╝████╗  ██║██╔═══██╗██║    ██║██║
    ███████╗██╔██╗ ██║██║   ██║██║ █╗ ██║██║
    ╚════██║██║╚██╗██║██║   ██║██║███╗██║╚═╝
    ███████║██║ ╚████║╚██████╔╝╚███╔███╔╝██╗
    ╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝ ╚═╝
    Developed by HPCNow! www.hpcnow.com/snow

    "
    echo "Get enterprise features and end user enterprise support from HPCNow!"
    echo "Please help us to improve this project, report bugs and issues to : "
    echo " sNow! Development <dev@hpcnow.com>"
    echo "If you found some error during the installation, please review the "
    echo "log file : $LOGFILE"
    echo "Some changes may require to reboot the system. Please, consider to do it "
    echo " before to move it into production."
    echo "--------------------------------------------------------------------------"
}

setup_software         && error_check 0 'Stage 1/9 : Software installed ' || error_check 1 'Stage 1/9 : Software installed ' &
spinner $!             'Stage 1/9 : Installing Software ' 
setup_networkfs        && error_check 0 'Stage 2/9 : Distributed filesystem setup ' || error_check 1 'Stage 2/9 : Distributed filesystem setup ' &
spinner $!             'Stage 2/9 : Setting distributed filesystem '
setup_ssh              && error_check 0 'Stage 3/9 : SSH service and sNow! users created ' || error_check 1 'Stage 3/9 : SSH service and sNow! users created ' & 
spinner $!             'Stage 3/9 : Creating SSH service and sNow! users '
setup_env              && error_check 0 'Stage 4/9 : User Environment configured ' || error_check 1 'Stage 4/9 : User Environment configuration ' & 
spinner $!             'Stage 4/9 : Configuring User Environment '
install_lmod           && error_check 0 'Stage 5/9 : Lmod install ' || error_check 1 'Stage 5/9 : Lmod install ' & 
spinner $!             'Stage 5/9 : Installing Lmod '
install_easybuild      && error_check 0 'Stage 6/9 : EasyBuild install ' || error_check 1 'Stage 6/9 : EasyBuild install ' & 
spinner $!             'Stage 6/9 : Installing EasyBuild '
setup_ldap_client      && error_check 0 'Stage 7/9 : LDAP client setup ' || error_check 1 'Stage 7/9 : LDAP client setup ' & 
spinner $!             'Stage 7/9 : Setting LDAP client '
setup_ganglia_client   && error_check 0 'Stage 8/9 : Ganglia client setup ' || error_check 1 'Stage 8/9 : Ganglia client setup ' & 
spinner $!             'Stage 8/9 : Setting Ganglia client '
setup_workload_client  && error_check 0 'Stage 9/9 : Workload Manager setup ' || error_check 1 'Stage 9/9 : Workload Manager setup ' & 
spinner $!             'Stage 9/9 : Setting Workload Manager '
hooks
first_boot_hooks
end_msg
