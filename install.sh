#!/bin/bash
# This is the sNow! Install Script
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow

#set -xv
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
readonly PROGNAME=$(basename "$0")
readonly SNOW_VERSION="${1:-1.1.15}"
trap "error_exit 'Received signal SIGHUP'" SIGHUP
trap "error_exit 'Received signal SIGINT'" SIGINT
trap "error_exit 'Received signal SIGTERM'" SIGTERM

# Check if the script is run by root
if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

# Default values for sNow! and HPCNow users
if [[ -z ${sNow_USER} ]];then
    sNow_USER=snow
fi
if [[ -z ${sNow_GROUP} ]];then
    sNow_GROUP=snow
fi
if [[ -z ${sNow_UID} ]];then
    sNow_UID=2000
fi
if [[ -z ${sNow_GID} ]];then
    sNow_GID=2000
fi
# By default HPCNow User is not created, unless HPCNow_Support is setup
if [[ -z ${HPCNow_Support} ]];then
    HPCNow_Support=none
fi
if [[ -z ${HPCNow_USER} ]];then
    HPCNow_USER=hpcnow
fi
if [[ -z ${HPCNow_GROUP} ]];then
    HPCNow_GROUP=snow
fi
if [[ -z ${HPCNow_UID} ]];then
    HPCNow_UID=2001
fi
if [[ -z ${HPCNow_GID} ]];then
    HPCNow_GID=2000
fi
# shellcheck disable=SC2034
declare -A CLUSTERS
# Allow to re-use existing or already customised snow.conf
if [[ -f ./etc/snow.conf ]]; then
    echo "Loading sNow! configuration..."
    source ./etc/snow.conf
elif [[ -f ./snow.conf ]]; then
    echo "Loading sNow! configuration..."
    source ./snow.conf
fi

readonly LOGFILE=/root/snow-install-$(uname -n).log

# The sNow and HPCNow users can not be updated if you are login the same session.
if [[ "${SUDO_USER}" == "${sNow_USER}" || "$SUDO_USER" == "$HPCNow_USER" ]]; then
    echo "The installation script needs to be run as root, without using $sNow_USER or $HPCNow_USER to scale privileges."
    exit 1
fi

# Use the default path values unless the environment variables are already setup.
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

if [[ -z "${SNOW_TOOL}" ]]; then
    SNOW_TOOL=${SNOW_PATH}/snow-tools
fi

if [[ -z "${SNOW_LOG}" ]]; then
    SNOW_LOG=${SNOW_PATH}/log
fi

# Use the default virtualization technology
if [[ -z "${VIRT_TECH}" ]]; then
    VIRT_TECH=XEN
fi

# If SNOW_NODES variable array is not provided, it will assume that the current node
# is the sNow! master node
if [[ "${#SNOW_NODES[@]}" == "0" ]]; then
    SNOW_NODES=( "$(uname -n)" )
fi

# If NFS_SERVER variable is not provided, it will assume that the current node
# is also the NFS server
if [[ -z "${NFS_SERVER}" ]]; then
    NFS_SERVER=$(uname -n)
fi

# In order to enable unattended installation, SNOW_EULA environment variable
# must be set to accepted. Otherwise, the installation will request the acceptance
# of the EULA.
if [[ -z "${SNOW_EULA}" ]]; then
    SNOW_EULA=interactive
fi

# By default there is no HPCNow! support arranged.
if [[ -z "${HPCNow_Support}" ]]; then
    HPCNow_Support=none
fi

readonly CONFIG_FILE=${SNOW_TOOL}/etc/snow.conf
readonly ENTERPRISE_EXTENSIONS=${SNOW_TOOL}/share/enterprise_extensions.sh
readonly SNOW_DOMAINS=${SNOW_TOOL}/etc/domains.conf
readonly SNOW_ACTIVE_DOMAINS=${SNOW_TOOL}/etc/active-domains.conf


if ! [[ -d ${SNOW_PATH} ]]; then
    mkdir -p ${SNOW_PATH}
fi
chown $sNow_UID:$sNow_GID $SNOW_PATH

function is_git_repo()
{
    local git_path=$1
    git -C ${git_path} rev-parse
    return $?
} &>/dev/null

function is_snow_node()
{
    # Returns 0 if this node is a golden node
    local sn=1
    for i in "${SNOW_NODES[@]}"; do
        if [[ "$(hostname -s)" == "$i" ]]; then
            local sn=0
        fi
    done
    return $sn
} 1>>$LOGFILE 2>&1

function is_nfs_server()
{
    hostname | grep "$NFS_SERVER"
    return $?
} &>/dev/null

function install_snow_repos()
{
if is_snow_node; then
    # If the configspace is not available, it must be created from scratch or pulled from git
    if [[ ! -e $SNOW_CONF ]]; then
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
    fi
    # Clone the git repo from HPCNow! or pull the updates from SNOW_VERSION release.
    if ! is_git_repo ${SNOW_TOOL}; then
        git clone http://bitbucket.org/hpcnow/snow-tools.git -b ${SNOW_VERSION} ${SNOW_TOOL} || echo "ERROR: please review the connection to bitbucket."
    else
        cd ${SNOW_TOOL} || exit
        git fetch
        git checkout ${SNOW_VERSION}
        git pull
        cd - || exit
    fi
    chown -R ${sNow_UID}:${sNow_GID} ${SNOW_TOOL}
fi
} &>/dev/null

function load_snow_env()
{
if [[ -f ${SNOW_TOOL}/share/common.sh ]]; then
    # shellcheck source=share/common.sh
    source ${SNOW_TOOL}/share/common.sh
    logsetup
    get_os_distro
    architecture_identification
    if [[ -f ${ENTERPRISE_EXTENSIONS} ]]; then
        # shellcheck source=share/enterprise_extensions.sh
        source ${ENTERPRISE_EXTENSIONS}
        has_ee=true
    else
        # shellcheck disable=SC2034
        has_ee=false
    fi
else
    echo "ERROR: There is a problem installing the public git repository to your file system"
    echo "       Please, review if you have access to this URL: http://bitbucket.org/hpcnow/snow-tools.git"
    echo "       and you have write access to the folder ${SNOW_TOOL}"
    exit 1
fi
}

function setup_filesystems()
{
    if is_snow_node && is_nfs_server; then
        check_mountpoints $SNOW_PATH
    else
        mkdir -p $SNOW_PATH
        mkdir -p $SNOW_HOME
        bkp /etc/fstab
        echo "$NFS_SERVER:$SNOW_PATH $SNOW_PATH    nfs    rw,tcp,bg,hard,intr,async,nodev,nosuid,defaults 0 0" >> /etc/fstab
        echo "$NFS_SERVER:$SNOW_HOME $SNOW_HOME    nfs    rw,tcp,bg,hard,intr,async,nodev,nosuid,defaults 0 0" >> /etc/fstab
        mount $SNOW_PATH
        mount $SNOW_HOME
    fi
    if [[ ! -e ${SNOW_LOG} ]]; then
        mkdir -p ${SNOW_LOG}
        touch ${SNOW_LOG}/snow.log
        chown -R root:root ${SNOW_LOG}
        chmod 600 ${SNOW_LOG}/snow.log
        chmod 700 ${SNOW_LOG}
    fi
} 1>>$LOGFILE 2>&1

function install_snow_dependencies()
{
    case $OS in
        debian)
            pkgs="build-essential libbz2-1.0 libssl-dev nfs-client rpcbind curl wget gawk patch pbzip2 unzip python-pip apt-transport-https ca-certificates members git parallel axel sudo consolekit bzip2 debian-archive-keyring dmidecode hwinfo ethtool firmware-bnx2 firmware-bnx2x firmware-linux-free firmware-realtek freeipmi genders nmap ntp ntpdate perftest openipmi ipmitool ifenslave raidutils lm-sensors dmsetup dnsutils fakeroot xfsprogs rsync syslinux-utils jq squashfs-tools lftp"
            if [[ "${OS_VERSION_MAJOR}" == "8" ]]; then
                pkgs="$pkgs python-software-properties"
            elif [[ "${OS_VERSION_MAJOR}" == "9" ]]; then
                pkgs="$pkgs software-properties-common"
            else
                error_msg "OS releases not supported"
            fi
            if is_snow_node && is_nfs_server ; then
                pkgs="$pkgs nfs-kernel-server nfs-common"
            fi
        ;;
        ubuntu)
            pkgs="build-essential libbz2-1.0 libssl-dev nfs-client rpcbind curl wget gawk patch pbzip2 unzip python-pip apt-transport-https ca-certificates members git parallel axel software-properties-common sudo bzip2 dmidecode hwinfo ethtool linux-firmware freeipmi genders nmap ntp ntpdate perftest openipmi ipmitool ifenslave raidutils lm-sensors dmsetup dnsutils fakeroot xfsprogs rsync syslinux-utils jq squashfs-tools automake autoconf m4 libtool autoconf-archive gnu-standards gettext lftp"
            if is_snow_node && is_nfs_server ; then
                pkgs="$pkgs nfs-kernel-server nfs-common"
            fi
        ;;
        rhel|redhat|centos)
            pkgs="epel-release @base @development-tools lsb libdb flex perl perl-Data-Dumper perl-Digest-MD5 perl-JSON perl-Parse-CPAN-Meta perl-CPAN pcre pcre-devel zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs nfs-utils rpcbind mdadm wget curl gawk patch unzip python-devel python-pip members git parallel jq squashfs-tools"
            if is_snow_node && is_nfs_server; then
                pkgs="$pkgs nfs-utils rpcbind"
            fi
        ;;
        suse|sle[sd])
            pkgs="libbz2-1 libz1 openssl libopenssl-devel gcc gcc-c++ nfs-client rpcbind wget curl gawk python-devel python-pip members git parallel jq squashfs-tools"
            if is_snow_node && is_nfs_server; then
                pkgs="$pkgs nfs-kernel-server"
            fi
        ;;
        opensuse)
            pkgs="libbz2-1 libz1 openssl libopenssl-devel gcc gcc-c++ nfs-client rpcbind wget curl gawk python-devel python-pip members git parallel jq"
            if is_snow_node && is_nfs_server; then
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
    if [[ ! -f  ${SNOW_TOOL}/eula.txt ]]; then
        echo "[E] The local sNow! tools repository is corrupted. Please, test your connection to bitbucket."
    fi
    more  ${SNOW_TOOL}/eula.txt
    if [[ "${SNOW_EULA}" == "accepted" ]]; then
        echo "EULA accepted. The installation will proceed (unattended mode)."
    else
        echo "Do you accept the EULA? type Accept or Decline"
        read input

        if [[ "$input" != "Accept"  ]]; then
            echo "The installation will not proceed"
            exit 1
        fi
    fi
    echo "--------------------------------------------------------------------------"
}

echo "[I] Downloading required files... This may take a while, Please wait."
install_snow_repos
eula
load_snow_env
setup_software         && error_check 0 'Stage 1/6 : Software installed ' || error_check 1 'Stage 1/6 : Software installed ' &
spinner $!             'Stage 1/6 : Installing Software '
setup_filesystems      && error_check 0 'Stage 2/6 : Filesystem setup ' || error_check 1 'Stage 2/6 : Filesystem setup ' &
spinner $!             'Stage 2/6 : Setting Filesystem '
setup_ssh              && error_check 0 'Stage 3/6 : SSH service and sNow! users created ' || error_check 1 'Stage 3/6 : SSH service and sNow! users created ' &
spinner $!             'Stage 3/6 : Creating SSH service and sNow! users '
setup_env              && error_check 0 'Stage 4/6 : User Environment configured ' || error_check 1 'Stage 4/6 : User Environment configured ' &
spinner $!             'Stage 4/6 : Configuring User Environment '
case $VIRT_TECH in
    XEN)
        setup_xen      && error_check 0 'Stage 5/6 : sNow! Xen installation ' || error_check 1 'Stage 5/6 : sNow! Xen installation ' &
        spinner $!     'Stage 5/6 : sNow! Xen installation '
    ;;
    LXD)
        echo "sNow! only supports XEN for production. LXD is experimental options at this time."
        setup_lxd      && error_check 0 'Stage 5/6 : sNow! LXD installation ' || error_check 1 'Stage 5/6 : sNow! LXD installation ' &
        spinner $!     'Stage 5/6 : sNow! LXD installation '
        lxd init
    ;;
    *)
        echo "sNow! only accepts the following options : XEN (default) and LXD (experimental)."
    ;;
esac
setup_devel_env_hpcnow && error_check 0 'Stage 6/6 : HPCNow! development environment setup ' || error_check 1 'Stage 6/6 : HPCNow! development environment setup ' &
spinner $!             'Stage 6/6 : HPCNow! development environment setup '
end_msg
