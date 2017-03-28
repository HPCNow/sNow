#!/bin/bash
# This is the sNow! Install Script
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow

#set -xv
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
readonly PROGNAME=$(basename "$0")
readonly SNOW_VERSION="1.1.0"
trap "error_exit 'Received signal SIGHUP'" SIGHUP
trap "error_exit 'Received signal SIGINT'" SIGINT
trap "error_exit 'Received signal SIGTERM'" SIGTERM

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [[ "$SUDO_USER" == "$sNow_USER" || "$SUDO_USER" == "$HPCNow_USER" ]]; then
    echo "The installation script needs to be run as root, without using $sNow_USER or $HPCNow_USER to scale privileges."
    exit 1
fi

if [[ -z "$PRIVATE_GIT_TOKEN" ]]; then
    echo "PRIVATE_GIT_TOKEN is not set. The snow-configspace will be created from scratch."
elif [[ -z "$PRIVATE_GIT_REPO" ]]; then
    echo "PRIVATE_GIT_REPO is not set. The snow-configspace will be created from scratch."
fi

if [[ -f ./etc/snow.conf ]]; then
    echo "Loading sNow! configuration..."
    source ./etc/snow.conf
elif [[ -f ./snow.conf ]]; then
    echo "Loading sNow! configuration..."
    source ./snow.conf
fi

LOGFILE=/tmp/snow-install-$(uname -n).log

if [[ -z "${SNOW_PATH}" ]]; then
    SNOW_PATH=/sNow
fi

if [[ -z "${SNOW_HOME}" ]]; then
    SNOW_HOME=/home
fi

if [[ -z "${SNOW_SOFT}" ]]; then
    SNOW_SOFT=${SNOW_PATH}/easybuild
fi

if [[ -z "${SNOW_CONF}" ]]; then
    SNOW_CONF=${SNOW_PATH}/snow-configspace
fi

if [[ -z "${SNOW_TOOLS}" ]]; then
    SNOW_TOOL=${SNOW_PATH}/snow-tools
fi

readonly CONFIG_FILE=${SNOW_TOOL}/etc/snow.conf
readonly ENTERPRISE_EXTENSIONS=${SNOW_TOOL}/share/enterprise_extensions.sh
readonly SNOW_DOMAINS=${SNOW_TOOL}/etc/domains.conf
readonly SNOW_ACTIVE_DOMAINS=${SNOW_TOOL}/etc/active-domains.conf
declare -A CLUSTERS
HAS_EE=false


if [[ ! -f ${SNOW_TOOL}/share/common.sh ]]; then
    if ! [[ -d ${SNOW_PATH} ]]; then
        mkdir -p ${SNOW_PATH}
    fi
    chown $sNow_USER:$sNow_USER $SNOW_PATH
    if [[ -z "$PRIVATE_GIT_TOKEN" && -z "$PRIVATE_GIT_REPO" ]]; then
        mkdir -p $SNOW_CONF 
    else
        git clone https://$PRIVATE_GIT_TOKEN:x-oauth-basic@$PRIVATE_GIT_REPO $SNOW_CONF || echo "ERROR: please review your tokens and repo URL."
    fi
    git clone http://bitbucket.org/hpcnow/snow-tools.git ${SNOW_TOOL} || echo "ERROR: please review the connection to bitbucket."
    git fetch
    git checkout ${SNOW_VERSION}
    if [[ -f ./etc/snow.conf ]]; then
        cp -p ./etc/snow.conf ${SNOW_TOOL}/etc/
    elif [[ -f ./snow.conf ]]; then
        cp -p ./snow.conf ${SNOW_TOOL}/etc/
    fi
    chown -R ${sNow_USER}:${sNow_USER} ${SNOW_TOOL}
fi

if [[ -f ${SNOW_TOOL}/share/common.sh ]]; then
    source ${SNOW_TOOL}/share/common.sh
    logsetup
    get_os_distro
    architecture_identification
fi

if [[ -f ${ENTERPRISE_EXTENSIONS} ]]; then
    source ${ENTERPRISE_EXTENSIONS}
    HAS_EE=true
fi

function is_master()
{
    hostname | grep "$MASTER_HOSTNAME"
    return $?
} &>/dev/null


function is_slave()
{
    hostname | grep -v "^$MASTER_HOSTNAME$" | grep "${SNOW_HOSTNAME_PREFIX}"
    return $?
} &>/dev/null

function is_nfs_server()
{
    hostname | grep "$NFS_SERVER"
    return $?
} &>/dev/null

function setup_filesystems()
{
    if is_master && is_nfs_server; then
        check_mountpoints $SNOW_PATH
        if [[ ! -e $SNOW_PATH/log ]]; then
            mkdir -p $SNOW_PATH/log
            touch $SNOW_PATH/log/snow.log
            chown -R root:root $SNOW_PATH/log/
            chmod 600 $SNOW_PATH/log/snow.log
            chmod 700 $SNOW_PATH/log
        fi
    else
        mkdir -p /sNow
        bkp /etc/fstab
        echo "$NFS_SERVER:$SNOW_PATH $SNOW_PATH    nfs4    nfs rw,rsize=4096,wsize=4096,bg,hard,intr,async,nodev,nosuid 0 0" >> /etc/fstab
        mount -a
    fi
} 1>>$LOGFILE 2>&1


function install_snow_repos()
{
    if is_master; then
        chown $sNow_USER:$sNow_USER $SNOW_PATH
        if [[ -z "$PRIVATE_GIT_TOKEN" && -z "$PRIVATE_GIT_REPO" ]]; then
            mkdir -p $SNOW_CONF 
        else
            git clone https://$PRIVATE_GIT_TOKEN:x-oauth-basic@$PRIVATE_GIT_REPO $SNOW_CONF || echo "ERROR: please review your tokens and repo URL."
        fi
        git clone http://bitbucket.org/hpcnow/snow-tools.git $SNOW_TOOL || echo "ERROR: please review the connection to bitbucket."
        chown -R $sNow_USER:$sNow_USER $SNOW_TOOL
        mkdir -p $SNOW_CONF/system_files/etc/ssh/
        cp -pr /etc/ssh/ssh_host_* $SNOW_CONF/system_files/etc/ssh/
    fi
} 1>>$LOGFILE 2>&1

function setup_snow_user()
{
    if is_master; then
        # Check UIDs and GIDs
        if [[ -z $(getent passwd $sNow_USER) ]]; then
            bkp /etc/group
            bkp /etc/passwd
            bkp /etc/shadow
            groupadd -g $sNow_GID $sNow_GROUP
            useradd -u $sNow_UID -g $sNow_GID -c "sNow! Admin User" -s /bin/bash -d $SNOW_HOME/$sNow_USER  $sNow_USER 
        elif [[ "$(id -u $sNow_USER)" != "$sNow_UID"  &&  "$(id -g $sNow_USER)" != "$sNow_GID" ]]; then
            groupmod -g $sNow_GID $sNow_GROUP
            usermod -u $sNow_UID -g $sNow_GID $sNow_USER
            usermod -c "sNow! Admin User" -g $sNow_GID -d $SNOW_HOME/$sNow_USER -s /bin/bash -m -u $sNow_UID $sNow_USER
        fi
        # Configure public key auth for the sNow! Admin User
        mkdir -p $SNOW_HOME/$sNow_USER/.ssh
        chown -R $sNow_USER:$sNow_GROUP $SNOW_HOME/$sNow_USER
        if [[ ! -f $SNOW_HOME/$sNow_USER/.ssh/id_rsa ]]; then
            sudo -u $sNow_USER ssh-keygen -t rsa -f $SNOW_HOME/$sNow_USER/.ssh/id_rsa -q -P ""
            bkp $SNOW_HOME/$sNow_USER/.ssh/authorized_keys
            cat $SNOW_HOME/$sNow_USER/.ssh/id_rsa.pub > $SNOW_HOME/$sNow_USER/.ssh/authorized_keys
            echo "Host *" > $SNOW_HOME/$sNow_USER/.ssh/config
            echo "    StrictHostKeyChecking no" >> $SNOW_HOME/$sNow_USER/.ssh/config
            echo "    UserKnownHostsFile /dev/null" >> $SNOW_HOME/$sNow_USER/.ssh/config
            echo "    PasswordAuthentication no" >> $SNOW_HOME/$sNow_USER/.ssh/config
            chown $sNow_USER:$sNow_GROUP $SNOW_HOME/$sNow_USER/.ssh/authorized_keys
            chown $sNow_USER:$sNow_GROUP $SNOW_HOME/$sNow_USER/.ssh/config
        fi
        # Don't require password for sNow! Admin user sudo
        bkp /etc/sudoers
        echo "$sNow_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
}

function setup_hpcnow_user()
{
    if is_master; then
        # Check UIDs and GIDs
        if [[ -z $(getent passwd $HPCNow_USER) ]]; then
            useradd -u $HPCNow_UID -g $HPCNow_GID -c "HPCNow! User" -s /bin/bash -d $SNOW_HOME/$HPCNow_USER  $HPCNow_USER 
        elif [[ "$(id -u $HPCNow_USER)" != "$HPCNow_UID"  &&  "$(id -g $HPCNow_USER)" != "$HPCNow_GID" ]]; then
            usermod -c "HPCNow! User" -g $HPCNow_GID -d $SNOW_HOME/$HPCNow_USER -s /bin/bash -m -u $HPCNow_UID $HPCNow_USER
        fi
        # Configure public key auth for the sNow! Admin User
        mkdir -p $SNOW_HOME/$HPCNow_USER/.ssh
        chown -R $HPCNow_USER:$HPCNow_GROUP $SNOW_HOME/$HPCNow_USER
        if [[ ! -f $SNOW_HOME/$HPCNow_USER/.ssh/id_rsa ]]; then
            sudo -u $HPCNow_USER ssh-keygen -t rsa -f $SNOW_HOME/$HPCNow_USER/.ssh/id_rsa -q -P ""
            cat $SNOW_HOME/$HPCNow_USER/.ssh/id_rsa.pub > $SNOW_HOME/$HPCNow_USER/.ssh/authorized_keys
            echo "Host *" > $SNOW_HOME/$HPCNow_USER/.ssh/config
            echo "    StrictHostKeyChecking no" >> $SNOW_HOME/$HPCNow_USER/.ssh/config
            echo "    UserKnownHostsFile /dev/null" >> $SNOW_HOME/$HPCNow_USER/.ssh/config
            echo "    PasswordAuthentication no" >> $SNOW_HOME/$HPCNow_USER/.ssh/config
            chown $HPCNow_USER:$HPCNow_GROUP $SNOW_HOME/$HPCNow_USER/.ssh/authorized_keys
            chown $HPCNow_USER:$HPCNow_GROUP $SNOW_HOME/$HPCNow_USER/.ssh/config
        fi
        # Don't require password for sNow! Admin user sudo
        echo "$HPCNow_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
}

# Setup SSH daemons, hosts keys and root SSH keys
function setup_ssh()
{
    if is_master; then
        setup_snow_user
        if [[ "$HPCNow_Support" != "none" ]]; then
            setup_hpcnow_user
        fi
        mkdir -p /root/.ssh
        cp -p $SNOW_HOME/$sNow_USER/.ssh/authorized_keys /root/.ssh/authorized_keys
        cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa /root/.ssh/
        cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa.pub /root/.ssh/
        chown -R root:root /root/.ssh
        chmod 700 /root/.ssh
        chmod 640 /root/.ssh/authorized_keys
        chmod 400 /root/.ssh/id_rsa
    else
        cp -pr $SNOW_CONF/system_files/etc/ssh/ssh_host_* /etc/ssh/
        cp -p $SNOW_CONF/system_files/etc/ssh/shosts.equiv /etc/ssh/
        chmod u+s /usr/lib64/ssh/ssh-keysign
        cp -p /etc/ssh/shosts.equiv /root/.shosts
        mkdir -p /root/.ssh
        cp -p $SNOW_HOME/$sNow_USER/.ssh/authorized_keys /root/.ssh/authorized_keys
        cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa /root/.ssh/
        cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa.pub /root/.ssh/
        chown -R root:root /root/.ssh
        chmod 700 /root/.ssh
        chmod 640 /root/.ssh/authorized_keys
        chmod 640 /root/.ssh/id_rsa
        systemctl restart sshd
    fi
}

function setup_env()
{
    # User enviroment setup
    ln -sf $SNOW_TOOL/bin/snow-source.sh /etc/profile.d/snow.sh
    ln -sf $SNOW_TOOL/bin/snow-source.csh /etc/profile.d/snow.csh
}

function install_software()
{
    case $OS in
        debian|ubuntu)
            pkgs="build-essential libbz2-1.0 libssl-dev nfs-client rpcbind curl wget gawk patch unzip python-pip apt-transport-https ca-certificates members git parallel axel python-software-properties sudo consolekit bzip2 debian-archive-keyring dmidecode hwinfo ethtool firmware-bnx2 firmware-bnx2x firmware-linux-free firmware-realtek freeipmi genders nmap ntp ntpdate perftest openipmi ipmitool ifenslave raidutils lm-sensors dmsetup dnsutils fakeroot xfsprogs rsync syslinux-utils jq"
            if is_master && $IS_NFSSERVER ; then
                pkgs="$pkgs nfs-kernel-server nfs-common"
            fi
            INSTALLER="apt-get -y install"
            apt-get -y update
        ;;
        rhel|redhat|centos)
            add_rhel_repos
            pkgs="epel-release @base @development-tools lsb libdb flex perl perl-Data-Dumper perl-Digest-MD5 perl-JSON perl-Parse-CPAN-Meta perl-CPAN pcre pcre-devel zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs nfs-utils rpcbind mdadm wget curl gawk patch unzip libibverbs libibverbs-devel python-devel python-pip members git parallel jq"
            if is_master && $IS_NFSSERVER ; then
                pkgs="$pkgs nfs-utils rpcbind"
            fi
            INSTALLER="yum -y install"
       ;;
       suse|sle[sd])
            add_sles_repos
            pkgs="libbz2-1 libz1 openssl libopenssl-devel gcc gcc-c++ nfs-client rpcbind wget curl gawk libibverbs libibverbs-devel python-devel python-pip members git parallel jq"
            if is_master && $IS_NFSSERVER ; then
                pkgs="$pkgs nfs-kernel-server"
            fi
            INSTALLER="zypper -n install"
       ;;
       opensuse)
            add_opensuse_repos
            pkgs="libbz2-1 libz1 openssl libopenssl-devel gcc gcc-c++ nfs-client rpcbind wget curl gawk libibverbs libibverbs-devel python-devel python-pip members git parallel jq"
            if is_master && $IS_NFSSERVER ; then
                pkgs="$pkgs nfs-kernel-server"
            fi
            INSTALLER="zypper -n install"
       ;;
   esac
   $INSTALLER $pkgs 
}

function setup_software()
{
    if is_master; then
        install_software 
    fi
} 1>>$LOGFILE 2>&1

function install_devel_env_hpcnow()
{
    case $OS in
        debian)
            pkgs="iotop iftop htop tmux psmisc byobu vim vim-nox iptraf traceroute pdsh clustershell"
            if ! is_master; then
                pkgs="$pkgs Lmod tcl tcl-devel"
            fi
            INSTALLER="apt-get -y install"
        ;;
        ubuntu)
            pkgs="build-essential libbz2-1.0 libssl-dev nfs-client rpcbind curl wget gawk libibverbs libibverbs-devel python-devel python-pip apt-transport-https ca-certificates members git parallel vim"
            if ! is_master; then
                pkgs="$pkgs Lmod tcl tcl-devel"
            fi
            INSTALLER="apt-get -y install"
        ;;
        rhel|redhat|centos)
            pkgs="epel-release @base @development-tools lsb libdb flex perl perl-Data-Dumper perl-Digest-MD5 perl-JSON perl-Parse-CPAN-Meta perl-CPAN pcre pcre-devel zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs nfs-utils rpcbind mdadm wget curl gawk patch unzip libibverbs libibverbs-devel python-devel python-pip members git parallel vim"
            if ! is_master; then
                pkgs="$pkgs Lmod tcl tcl-devel"
            fi
            INSTALLER="yum -y install"
       ;;
       suse|sle[sd]|opensuse)
            pkgs="libbz2-1 libz1 openssl libopenssl-devel gcc gcc-c++ nfs-client rpcbind wget curl gawk libibverbs libibverbs-devel python-devel python-pip members git parallel vim"
            if ! is_master; then
                pkgs="$pkgs Lmod tcl tcl-devel"
            fi
            INSTALLER="zypper -n install"
       ;;
   esac
   $INSTALLER $pkgs
}

function setup_devel_env_hpcnow()
{
    if is_master; then
        install_devel_env_hpcnow 
        git clone https://github.com/HPCNow/dotfiles.git /dev/shm/dotfiles
        cd /dev/shm/dotfiles
        bash dotfiles.sh
        git clone https://github.com/squash/sudosh2.git /dev/shm/sudosh2
        cd /dev/shm/sudosh2
        ./configure 
        make
        make install 
        sudosh -i 
        mkdir -p /usr/share/images/grub
        bkp /etc/default/grub
        echo "GRUB_BACKGROUND=\"/usr/share/images/grub/snow-grub-bg.png\"" >> /etc/default/grub 
        wget http://hpcnow.com/images/snow/snow-grub-bg.png -O /usr/share/images/grub/snow-grub-bg.png
        update-grub
    else
        echo "nothing to do here"
    fi
} 1>>$LOGFILE 2>&1


function eula()
{
    if [[ ! -f ./eula.txt ]]; then
        wget http://www.hpcnow.com/snow/eula.txt
    fi
    more ./eula.txt
    echo "Do you accept the EULA? type Accept or Decline"
    read input                                                 

    if [[ "$input" != "Accept"  ]] ; then                                  
        echo "The installation will not proceed"
        exit 1
    fi
    echo "--------------------------------------------------------------------------"
}

get_os_distro
eula
setup_software         && error_check 0 'Stage 1/7 : Software installed ' || error_check 1 'Stage 1/7 : Software installed ' &
spinner $!             'Stage 1/7 : Installing Software ' 
setup_filesystems      && error_check 0 'Stage 2/7 : Filesystem setup ' || error_check 1 'Stage 2/7 : Filesystem setup ' &
spinner $!             'Stage 2/7 : Setting Filesystem '
setup_ssh              && error_check 0 'Stage 3/7 : SSH service and sNow! users created ' || error_check 1 'Stage 3/7 : SSH service and sNow! users created ' & 
spinner $!             'Stage 3/7 : Creating SSH service and sNow! users '
install_snow_repos     && error_check 0 'Stage 4/7 : sNow! repos installed ' || error_check 1 'Stage 4/7 : sNow! repos installed ' & 
spinner $!             'Stage 4/7 : sNow! repos installed '
setup_env              && error_check 0 'Stage 5/7 : User Environment configured ' || error_check 1 'Stage 5/7 : User Environment configured ' & 
spinner $!             'Stage 5/7 : Configuring User Environment '
case $VIRT_TECH in
    XEN)
        setup_xen      && error_check 0 'Stage 6/7 : sNow! Xen installation ' || error_check 1 'Stage 6/7 : sNow! Xen installation ' & 
        spinner $!     'Stage 6/7 : sNow! Xen installation '
    ;;
    DOCKER)
        echo "sNow! only supports XEN for production. DOCKER and LXD are experimental options at this time."
        setup_docker   && error_check 0 'Stage 6/7 : sNow! Docker installed ' || error_check 1 'Stage 6/7 : sNow! Docker installed ' & 
        spinner $!     'Stage 6/7 : sNow! Docker installation '
    ;;
    LXD)
        echo "sNow! only supports XEN for production. DOCKER and LXD are experimental options at this time."
        setup_lxd      && error_check 0 'Stage 6/7 : sNow! LXD installation ' || error_check 1 'Stage 6/7 : sNow! LXD installation ' & 
        spinner $!     'Stage 6/7 : sNow! LXD installation '
        lxd init
    ;;
    *)
        echo "sNow! only accepts the following options : XEN (default), DOCKER (experimental) and LXD (experimental)."
    ;;
esac
setup_devel_env_hpcnow && error_check 0 'Stage 7/7 : HPCNow! development environment setup ' || error_check 1 'Stage 7/7 : HPCNow! development environment setup ' &
spinner $!             'Stage 7/7 : HPCNow! development environment setup '
end_msg
