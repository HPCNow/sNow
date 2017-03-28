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

# Check if the script is run by root
if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [[ "$SUDO_USER" == "$sNow_USER" || "$SUDO_USER" == "$HPCNow_USER" ]]; then
    echo "The installation script needs to be run as root, without using $sNow_USER or $HPCNow_USER to scale privileges."
    exit 1
fi


# Allow to re-use existing or already customised snow.conf
if [[ -f ./etc/snow.conf ]]; then
    echo "Loading sNow! configuration..."
    source ./etc/snow.conf
elif [[ -f ./snow.conf ]]; then
    echo "Loading sNow! configuration..."
    source ./snow.conf
fi

LOGFILE=/tmp/snow-install-$(uname -n).log

# Use the default values unless the environment variables are already setup.
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

if [[ -z "${SNOW_LOG}" ]]; then
    SNOW_LOG=${SNOW_PATH}/log
fi

if [[ -z "${VIRT_TECH}" ]]; then
    VIRT_TECH=XEN
fi

if [[ -z "${SNOW_MASTER}" ]]; then
    SNOW_MASTER=$(uname -n)
fi

if [[ -z "${NFS_SERVER}" ]]; then
    NFS_SERVER=$(uname -n)
fi

if [[ -z "${HPCNow_Support}" ]]; then
    HPCNow_Support=none
fi

readonly CONFIG_FILE=${SNOW_TOOL}/etc/snow.conf
readonly ENTERPRISE_EXTENSIONS=${SNOW_TOOL}/share/enterprise_extensions.sh
readonly SNOW_DOMAINS=${SNOW_TOOL}/etc/domains.conf
readonly SNOW_ACTIVE_DOMAINS=${SNOW_TOOL}/etc/active-domains.conf
declare -A CLUSTERS


if ! [[ -d ${SNOW_PATH} ]]; then
    mkdir -p ${SNOW_PATH}
fi
chown $sNow_USER:$sNow_USER $SNOW_PATH

function is_git_repo()
{
    local git_path=$1
    git -C ${git_path} rev-parse
    return $?
} &>/dev/null

function is_master()
{
    hostname | grep "$SNOW_MASTER"
    return $?
} &>/dev/null


function is_slave()
{
    hostname | grep -v "^$SNOW_MASTER$" | grep "${SNOW_HOSTNAME_PREFIX}"
    return $?
} &>/dev/null

function is_nfs_server()
{
    hostname | grep "$NFS_SERVER"
    return $?
} &>/dev/null

if is_master; then
    # Justify why snow-configspace is created from scratch
    if [[ -z "$PRIVATE_GIT_TOKEN" ]]; then
        echo "PRIVATE_GIT_TOKEN is not set. The snow-configspace will be created from scratch."
    elif [[ -z "$PRIVATE_GIT_REPO" ]]; then
        echo "PRIVATE_GIT_REPO is not set. The snow-configspace will be created from scratch."
    fi
    # Allow to re-use existing or already customised snow.conf
    if [[ -z "$PRIVATE_GIT_TOKEN" && -z "$PRIVATE_GIT_REPO" ]]; then
        mkdir -p $SNOW_CONF 
        # Transfer the SSH host keys to the configspace
        mkdir -p $SNOW_CONF/system_files/etc/ssh/
        cp -pr /etc/ssh/ssh_host_* $SNOW_CONF/system_files/etc/ssh/
        if [[ -f ./etc/snow.conf ]]; then
            cp -p ./etc/snow.conf ${SNOW_TOOL}/etc/
        elif [[ -f ./snow.conf ]]; then
            cp -p ./snow.conf ${SNOW_TOOL}/etc/
        fi
    else
        git clone https://$PRIVATE_GIT_TOKEN:x-oauth-basic@$PRIVATE_GIT_REPO $SNOW_CONF || echo "ERROR: please review your tokens and repo URL."
    fi
    # Clone the git repo from HPCNow! or pull the updates from SNOW_VERSION release.
    if ! is_git_repo ${SNOW_TOOL}; then
        git clone http://bitbucket.org/hpcnow/snow-tools.git ${SNOW_TOOL} || echo "ERROR: please review the connection to bitbucket."
        git fetch
        git checkout ${SNOW_VERSION}
        git pull
    else
        git fetch
        git checkout ${SNOW_VERSION}
        git pull
    fi
    chown -R ${sNow_USER}:${sNow_USER} ${SNOW_TOOL}
fi

if [[ -f ${SNOW_TOOL}/share/common.sh ]]; then
    source ${SNOW_TOOL}/share/common.sh
    logsetup
    get_os_distro
    architecture_identification
    if [[ -f ${ENTERPRISE_EXTENSIONS} ]]; then
        source ${ENTERPRISE_EXTENSIONS}
        has_ee=true
    else 
        has_ee=false
    fi
else
    echo "ERROR: There is a problem installing the public git repository to your file system"
    echo "       Please, review if you have access to this URL: http://bitbucket.org/hpcnow/snow-tools.git"
    echo "       and you have write access to the folder ${SNOW_TOOL}"
    exit 1
fi

function setup_filesystems()
{
    if is_master && is_nfs_server; then
        check_mountpoints $SNOW_PATH
        if [[ ! -e ${SNOW_LOG} ]]; then
            mkdir -p ${SNOW_LOG}
            touch ${SNOW_LOG}/snow.log
            chown -R root:root ${SNOW_LOG}
            chmod 600 ${SNOW_LOG}/snow.log
            chmod 700 ${SNOW_LOG}
        fi
    else
        mkdir -p $SNOW_PATH
        mkdir -p $SNOW_HOME
        bkp /etc/fstab
        echo "$NFS_SERVER:$SNOW_PATH $SNOW_PATH    nfs    rw,tcp,bg,hard,intr,async,nodev,nosuid,defaults 0 0" >> /etc/fstab
        echo "$NFS_SERVER:$SNOW_HOME $SNOW_HOME    nfs    rw,tcp,bg,hard,intr,async,nodev,nosuid,defaults 0 0" >> /etc/fstab
        mount $SNOW_PATH
        mount $SNOW_HOME
    fi
} 1>>$LOGFILE 2>&1

function install_snow_dependencies()
{
    case $OS in
        debian|ubuntu)
            pkgs="build-essential libbz2-1.0 libssl-dev nfs-client rpcbind curl wget gawk patch unzip python-pip apt-transport-https ca-certificates members git parallel axel python-software-properties sudo consolekit bzip2 debian-archive-keyring dmidecode hwinfo ethtool firmware-bnx2 firmware-bnx2x firmware-linux-free firmware-realtek freeipmi genders nmap ntp ntpdate perftest openipmi ipmitool ifenslave raidutils lm-sensors dmsetup dnsutils fakeroot xfsprogs rsync syslinux-utils jq"
            if is_master && is_nfs_server ; then
                pkgs="$pkgs nfs-kernel-server nfs-common"
            fi
        ;;
        rhel|redhat|centos)
            pkgs="epel-release @base @development-tools lsb libdb flex perl perl-Data-Dumper perl-Digest-MD5 perl-JSON perl-Parse-CPAN-Meta perl-CPAN pcre pcre-devel zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs nfs-utils rpcbind mdadm wget curl gawk patch unzip libibverbs libibverbs-devel python-devel python-pip members git parallel jq"
            if is_master && is_nfs_server; then
                pkgs="$pkgs nfs-utils rpcbind"
            fi
        ;;
        suse|sle[sd])
            pkgs="libbz2-1 libz1 openssl libopenssl-devel gcc gcc-c++ nfs-client rpcbind wget curl gawk libibverbs libibverbs-devel python-devel python-pip members git parallel jq"
            if is_master && is_nfs_server; then
                pkgs="$pkgs nfs-kernel-server"
            fi
        ;;
        opensuse)
            pkgs="libbz2-1 libz1 openssl libopenssl-devel gcc gcc-c++ nfs-client rpcbind wget curl gawk libibverbs libibverbs-devel python-devel python-pip members git parallel jq"
            if is_master && is_nfs_server; then
                pkgs="$pkgs nfs-kernel-server"
            fi
        ;;
    esac
    install_software "$pkgs"
}

function setup_software()
{
    install_snow_dependencies
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
#install_snow_repos     && error_check 0 'Stage 4/7 : sNow! repos installed ' || error_check 1 'Stage 4/7 : sNow! repos installed ' & 
#spinner $!             'Stage 4/7 : sNow! repos installed '
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
