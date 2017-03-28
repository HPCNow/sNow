#!/bin/bash
# This is the sNow! Install Script
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow

#set -xeuo pipefail
#set -xv
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
readonly PROGNAME=$(basename "$0")
readonly SNOW_VERSION="1.1.0"
trap "error_exit 'Received signal SIGHUP'" SIGHUP
trap "error_exit 'Received signal SIGINT'" SIGINT
trap "error_exit 'Received signal SIGTERM'" SIGTERM

if [[ -f ./etc/snow.conf ]]; then
    echo "Loading custom parameters ..."
    source ./etc/snow.conf
else
    wget -q http://www.hpckp.org/snow/snow-env.sh 
    source ./snow-env.sh
fi

if [[ ! -f ./eula.txt ]]; then
    wget -q http://www.hpckp.org/snow/eula.txt
fi

if [[ ! -f ./eula.txt ]]; then
    wget -q http://www.hpckp.org/snow/eula.txt
fi


if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [[ "$SUDO_USER" == "$sNow_USER" || "$SUDO_USER" == "$HPCNow_USER" ]]; then
    echo "The installation script needs to be run as root, without using $sNow_USER or $HPCNow_USER to scale privileges."
    exit 1
fi

# Check private repos
export PRIVATE_GIT_TOKEN=${PRIVATE_GIT_TOKEN:-$1}
export PRIVATE_GIT_REPO=${PRIVATE_GIT_REPO:-$2}

if [[ -z "$PRIVATE_GIT_TOKEN" ]]; then
    echo "PRIVATE_GIT_TOKEN is not set. The snow-configspace will be created from scratch."
fi

if [[ -z "$PRIVATE_GIT_REPO" ]]; then
    echo "PRIVATE_GIT_REPO is not set. The snow-configspace will be created from scratch."
fi

LOGFILE=/tmp/snow-install.log
RETAIN_NUM_LINES=10

function logsetup() 
{
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
}

#logsetup
        
function log()
{
    echo "[$(date)]: $*" 
}

function spinner()
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

function error_check()
{
    local status=$1
    printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" 
    if [ $status -eq 0 ]; then
        printf "[\e[0;32m%c\e[m] %s \e[0;32m%s\e[m \n" "*" "$2" "OK"
    else
        printf "[\e[0;31m%c\e[m] %s \e[0;31m%s\e[m \n" "!" "$2" "FAIL"
        error_msg
        exit
    fi
}
        
function bkp()
{
    bkpfile=$1
    next=$(date +%Y%m%d%H%M)
    if [[ -e $bkpfile ]]; then 
        cp -pr $bkpfile $bkpfile.$next-snowbkp
    fi
}

function get_os_distro() 
{
    # OS release and Service pack discovery 
    lsb_dist=$(lsb_release -si 2>&1 | tr '[:upper:]' '[:lower:]' | tr -d '[[:space:]]')
    dist_version=$(lsb_release -sr 2>&1 | tr '[:upper:]' '[:lower:]' | tr -d '[[:space:]]')
    # Special case redhatenterpriseserver
    if [ "${lsb_dist}" = "redhatenterpriseserver" ]; then
        lsb_dist='redhat'
    fi
    if [ "${lsb_dist}" = "suselinux" ]; then
        lsb_dist='suse'
    fi
    if [[ -z "${lsb_dist}" ]]; then
        lsb_dist=$(uname -s)
    else
        export OSVERSION=${dist_version}
    fi
    export OS=$lsb_dist
} #1>>$LOGFILE 2>&1

# Returns 0 if this node is the master node.
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

# Check mountpoints
function check_mountpoints()
{
    IS_MOUNTPOINT=$(mountpoint -d $1)
    if [ -n "$IS_MOUNTPOINT" ]; then
        echo "The $1 should be a dedicated filesystem. For HA it should be a reliable cluster filesystem."
    fi
}

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

function install_docker()
{
    case $OS in
        debian)
            apt-get -y purge lxc-docker*
            apt-get -y purge docker.io*
            apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
            echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
            apt-get -y update
            apt-cache policy docker-engine
            apt-get -y install docker-engine
            groupadd docker
            gpasswd -a $sNow_USER docker
            service docker restart
        ;;
        ubuntu)
            apt-get -y install linux-image-extra-$(uname -r)
            apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
            echo "deb https://apt.dockerproject.org/repo ubuntu-wily main" > /etc/apt/sources.list.d/docker.list
            apt-get -y update
            apt-get -y purge lxc-docker
            apt-cache policy docker-engine
            apt-get -y install docker-engine
            usermod -aG docker $sNow_USER
            echo "GRUB_CMDLINE_LINUX=\"cgroup_enable=memory swapaccount=1\"" >> /etc/default/grub
            update-grub
            service docker start
            systemctl enable docker
        ;;
        rhel|redhat|centos)
            yum -y update
            curl -sSL https://get.docker.com/ | sh
            usermod -aG docker $sNow_USER
            chkconfig docker on
            service docker start
       ;;
       suse|sle[sd]|opensuse)
           zypper -n --no-gpg-checks in docker
           /usr/sbin/usermod -a -G docker $sNow_USER
           echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
           sysctl -p /etc/sysctl.conf
           systemctl start docker
           systemctl enable docker
       ;;
   esac
}

function setup_docker()
{
    if is_master; then
        install_docker
        curl -L https://github.com/docker/compose/releases/download/1.6.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        #su - $sNow_USER -c "cd $SNOW_CONF/docker_files; docker-compose up -d"
    else
        echo "Nothing to be done yet"
    fi
} 1>>$LOGFILE 2>&1

function install_lxd()
{
    case $OS in
        debian)
            echo "sNow! LXD Support not yet available for $OS"
            exit 1
        ;;
        ubuntu)
            apt-get -y install lxd zfsutils-linux
        ;;
        rhel|redhat|centos)
            echo "sNow! LXD Support not yet available for $OS"
            exit 1
       ;;
       suse|sle[sd]|opensuse)
            echo "sNow! LXD Support not yet available for $OS"
            exit 1
       ;;
   esac
}

function setup_lxd()
{
    if is_master; then
        install_lxd
    else
        echo "Nothing to be done yet"
    fi
} 1>>$LOGFILE 2>&1



function install_xen()
{
    case $OS in
        debian)
            # Following suggestions from Debian : https://wiki.debian.org/Xen
            if [[ -f /etc/default/cpufrequtils ]]; then
                bkp /etc/default/cpufrequtils
                sed -i '/GOVERNOR/s/=.*/="performance"/' /etc/default/cpufrequtils
            fi
            apt-get -y update
            apt-get -y install xen-linux-system xen-tools
            dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
            sed -i '/TOOLSTACK/s/=.*/=xl/' /etc/default/xen
            #sed -i 's/GRUB_CMDLINE_XEN_DEFAULT=/GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=4096M,max:4096M dom0_max_vcpus=2 dom0_vcpus_pin\"/' /etc/default/grub
            bkp /etc/default/grub
            echo 'GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=4096M,max:4096M dom0_max_vcpus=2 dom0_vcpus_pin"' >> /etc/default/grub
            echo 'GRUB_DISABLE_OS_PROBER=true' >> /etc/default/grub
            #sed -i 's/(dom0-min-mem 1024)/(dom0-min-mem 4096)/' /etc/xen/xend-config.sxp
            #sed -i 's/(dom0-cpus 2)/(dom0-min-mem 4096)/' /etc/xen/xend-config.sxp
            bkp /etc/default/xendomains
            sed -i 's/XENDOMAINS_RESTORE=true/XENDOMAINS_RESTORE=false/' /etc/default/xendomains
            sed -i 's/XENDOMAINS_SAVE=\/var\/lib\/xen\/save/XENDOMAINS_SAVE=/' /etc/default/xendomains
            bkp /etc/sysctl.conf
            sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
        ;;
        ubuntu)
            # Following suggestions from Debian : https://wiki.debian.org/Xen
            sed -i '/GOVERNOR/s/=.*/="performance"/' /etc/default/cpufrequtils
            apt-get -y update
            apt-get -y xen-linux-system xen-tools
            dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
            sed -i '/TOOLSTACK/s/=.*/=xl/' /etc/default/xen
            sed -i 's/GRUB_CMDLINE_XEN_DEFAULT=/GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=4096M,max:4096M dom0_max_vcpus=2 dom0_vcpus_pin\"/' /etc/default/grub
            echo 'GRUB_DISABLE_OS_PROBER=true' >> /etc/default/grub
            sed -i 's/(dom0-min-mem 1024)/(dom0-min-mem 4096)/' /etc/xen/xend-config.sxp
            sed -i 's/(dom0-cpus 2)/(dom0-min-mem 4096)/' /etc/xen/xend-config.sxp
            sed -i 's/XENDOMAINS_RESTORE=true/XENDOMAINS_RESTORE=false/' /etc/default/xendomains
            sed -i 's/XENDOMAINS_SAVE=\/var\/lib\/xen\/save/XENDOMAINS_SAVE=/' /etc/default/xendomains
        ;;
        centos)
            echo "sNow! Xen Support not yet available for RHEL and CentOS"
            exit 1
            yum -y install centos-release-xen bridge-utils SDL net-tools
            yum -y update
            yum -y install xen
            systemctl stop NetworkManager
            systemctl disable NetworkManager
       ;;
        rhel|redhat)
            echo "sNow! Xen Support not yet available for RHEL and CentOS"
            exit 1
            yum -y install xen kernel-xen
       ;;
       suse|sle[sd]|opensuse)
            echo "sNow! Xen Support not yet available for SLES and OpenSUSE"
            exit 1
            zypper -n --no-gpg-checks in -t pattern xen_server
       ;;
   esac
}

function setup_xen()
{
    if is_master; then
        install_xen
    else
        echo "Nothing to be done yet"
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

function end_msg(){
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
    echo "The node needs to be rebooted after the installation in order to apply the"
    echo "changes merged in the system."
    echo "--------------------------------------------------------------------------"
}

function error_msg(){
    echo "--------------------------------------------------------------------------"
    echo "Please help us to improve this project, report bugs and issues to : "
    echo " sNow! Development <dev@hpcnow.com>"
    echo "If you found some error during the installation, please review the "
    echo "log file : $LOGFILE"
    echo "--------------------------------------------------------------------------"
}

function eula(){
    if [[ ! -f ./snow-eula.txt ]]; then
        wget http://www.hpcnow.com/snow/snow-eula.txt
    fi
    more ./snow-eula.txt
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
