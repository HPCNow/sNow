#!/bin/bash
# This is the sNow! Install Script
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow

#set -xv
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
readonly PROGNAME=$(basename "$0")
readonly SNOW_VERSION="${1:-2.0.0}"
trap "error_exit 'Received signal SIGHUP'" SIGHUP
trap "error_exit 'Received signal SIGINT'" SIGINT
trap "error_exit 'Received signal SIGTERM'" SIGTERM

# Check if the script is run by root
if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

# Default values for sNow! and HPCNow users
if [[ -z ${SNOW_USER} ]];then
    SNOW_USER=snow
fi
if [[ -z ${SNOW_GROUP} ]];then
    SNOW_GROUP=snow
fi
if [[ -z ${SNOW_UID} ]];then
    SNOW_UID=2000
fi
if [[ -z ${SNOW_GID} ]];then
    SNOW_GID=2000
fi
# By default HPCNow User is not created, unless HPCNOW_SUPPORT is setup
if [[ -z ${HPCNOW_SUPPORT} ]];then
    HPCNOW_SUPPORT=none
fi
if [[ -z ${HPCNOW_USER} ]];then
    HPCNOW_USER=hpcnow
fi
if [[ -z ${HPCNOW_GROUP} ]];then
    HPCNOW_GROUP=snow
fi
if [[ -z ${HPCNOW_UID} ]];then
    HPCNOW_UID=2001
fi
if [[ -z ${HPCNOW_GID} ]];then
    HPCNOW_GID=2000
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
if [[ "${SUDO_USER}" == "${SNOW_USER}" || "$SUDO_USER" == "$HPCNOW_USER" ]]; then
    echo "The installation script needs to be run as root, without using $SNOW_USER or $HPCNOW_USER to scale privileges."
    exit 1
fi

# Use the default path values unless the environment variables are already setup.
if [[ -z ${SNOW_ROOT} ]]; then
    SNOW_ROOT=/sNow
fi
if [[ -z ${SNOW_HOME} ]]; then
    SNOW_HOME=/home
fi
if [[ -z ${SNOW_BIN} ]]; then
    SNOW_BIN=${SNOW_ROOT}/bin
fi
if [[ -z ${SNOW_SBIN} ]]; then
    SNOW_SBIN=${SNOW_ROOT}/sbin
fi
if [[ -z ${SNOW_ETC} ]]; then
    SNOW_ETC=${SNOW_ETC}
fi
if [[ -z ${SNOW_LIB} ]]; then
    SNOW_LIB=${SNOW_ROOT}/lib
fi
if [[ -z ${SNOW_SHARE} ]]; then
    SNOW_SHARE=${SNOW_ROOT}/share
fi
if [[ -z ${SNOW_SRV} ]]; then
    SNOW_SRV=${SNOW_ROOT}/srv
fi
if [[ -z ${SNOW_VAR} ]]; then
    SNOW_VAR=${SNOW_ROOT}/var
fi
if [[ -z ${SNOW_LOG} ]]; then
    SNOW_LOG=${SNOW_ROOT}/var/log
fi
if [[ -z ${SNOW_MAN} ]]; then
    SNOW_MAN=${SNOW_ROOT}/man
fi
if [[ -z ${SNOW_TEST} ]]; then
    SNOW_TEST=${SNOW_ROOT}/test
fi
if [[ -z ${SNOW_CONTRIB} ]]; then
    SNOW_CONTRIB=${SNOW_ROOT}/contrib
fi
if [[ -z ${SNOW_EASYBUILD} ]]; then
    SNOW_EASYBUILD=${SNOW_ROOT}/easybuild
fi
if [[ -z ${SNOW_DOC} ]]; then
    SNOW_DOC=${SNOW_ROOT}/doc
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
if [[ -z "${HPCNOW_SUPPORT}" ]]; then
    HPCNOW_SUPPORT=none
fi

readonly CONFIG_FILE=${SNOW_ETC}/snow.conf
readonly ENTERPRISE_EXTENSIONS=${SNOW_ROOT}/lib/enterprise_extensions.sh
readonly SNOW_DOMAINS=${SNOW_ETC}/domains.conf
readonly SNOW_ACTIVE_DOMAINS=${SNOW_ETC}/active-domains.conf


if ! [[ -d ${SNOW_ROOT} ]]; then
    mkdir -p ${SNOW_ROOT}
fi
chown $SNOW_UID:$SNOW_GID $SNOW_ROOT

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

function setup_snow_env() {
  echo "#!/bin/bash" > /etc/profile.d/00-snow-env.sh
  echo "export SNOW_ROOT=${SNOW_ROOT}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_HOME=${SNOW_HOME}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_BIN=${SNOW_BIN}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_SBIN=${SNOW_SBIN}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_ETC=${SNOW_ETC}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_LIB=${SNOW_LIB}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_SHARE=${SNOW_SHARE}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_SRV=${SNOW_SRV}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_VAR=${SNOW_VAR}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_LOG=${SNOW_LOG}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_MAN=${SNOW_MAN}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_TEST=${SNOW_TEST}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_CONTRIB=${SNOW_CONTRIB}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_EASYBUILD=${SNOW_EASYBUILD}" >> /etc/profile.d/00-snow-env.sh
  echo "export SNOW_DOC=${SNOW_DOC}" >> /etc/profile.d/00-snow-env.sh
  echo "#!/bin/csh" > /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_ROOT ${SNOW_ROOT}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_BIN ${SNOW_BIN}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_SBIN ${SNOW_SBIN}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_ETC ${SNOW_ETC}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_LIB ${SNOW_LIB}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_SHARE ${SNOW_SHARE}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_SRV ${SNOW_SRV}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_VAR ${SNOW_VAR}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_LOG ${SNOW_LOG}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_MAN ${SNOW_MAN}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_TEST ${SNOW_TEST}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_CONTRIB ${SNOW_CONTRIB}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_EASYBUILD ${SNOW_EASYBUILD}" >> /etc/profile.d/00-snow-env.csh
  echo "setenv SNOW_DOC ${SNOW_DOC}" >> /etc/profile.d/00-snow-env.csh
  ln -sf ${SNOW_ETC}/profile.d/snow-source.sh /etc/profile.d/
  ln -sf ${SNOW_ETC}/profile.d/snow-source.csh /etc/profile.d/

} 1>>$LOGFILE 2>&1

function install_snow_repos()
{
if is_snow_node; then
    # If the configspace is not available, it must be created from scratch or pulled from git
    if [[ ! -e ${SNOW_SRV} ]]; then
        # Justify why snow-configspace is created from scratch
        if [[ -z "$PRIVATE_GIT_TOKEN" ]]; then
            echo "PRIVATE_GIT_TOKEN is not set. The snow-configspace will be created from scratch."
        elif [[ -z "$PRIVATE_GIT_REPO" ]]; then
            echo "PRIVATE_GIT_REPO is not set. The snow-configspace will be created from scratch."
        fi
        # Allow to re-use existing or already customised snow.conf
        if [[ -z "$PRIVATE_GIT_TOKEN" && -z "$PRIVATE_GIT_REPO" ]]; then
            mkdir -p $SNOW_SRV/deploy_files/
            # Transfer the SSH host keys to the configspace
            mkdir -p $SNOW_SRV/deploy_files/etc/ssh/
            cp -pr /etc/ssh/ssh_host_* $SNOW_SRV/deploy_files/etc/ssh/
            if [[ -f ./etc/snow.conf ]]; then
                cp -p ./etc/snow.conf ${SNOW_ETC}/
            elif [[ -f ./snow.conf ]]; then
                cp -p ./snow.conf ${SNOW_ETC}/
            fi
        else
            git clone https://$PRIVATE_GIT_TOKEN:x-oauth-basic@$PRIVATE_GIT_REPO $SNOW_SRV || echo "ERROR: please review your tokens and repo URL."
        fi
    fi
    # Clone the git repo from HPCNow! or pull the updates from SNOW_VERSION release.
    if ! is_git_repo ${SNOW_ROOT}; then
        git clone https://github.com/HPCNow/sNow.git -b ${SNOW_VERSION} ${SNOW_ROOT} || echo "ERROR: please review the connection to GitHub."
    else
        cd ${SNOW_ROOT} || exit
        git fetch
        git checkout ${SNOW_VERSION}
        git pull
        cd - || exit
    fi
    chown -R ${SNOW_UID}:${SNOW_GID} ${SNOW_ROOT}
fi
} &>/dev/null

function load_snow_env()
{
if [[ -f ${SNOW_LIB}/common.sh ]]; then
    # shellcheck source=share/common.sh
    source ${SNOW_LIB}/common.sh
    logsetup
    get_os_distro
    architecture_identification
    if [[ -f ${ENTERPRISE_EXTENSIONS} ]]; then
        # shellcheck source=lib/enterprise_extensions.sh
        source ${ENTERPRISE_EXTENSIONS}
        has_ee=true
    else
        # shellcheck disable=SC2034
        has_ee=false
    fi
else
    echo "ERROR: There is a problem installing the public git repository to your file system"
    echo "       Please, review if you have access to this URL: https://github.com/HPCNow/sNow.git"
    echo "       and you have write access to the folder ${SNOW_ROOT}"
    exit 1
fi
}

function setup_filesystems()
{
    if is_snow_node && is_nfs_server; then
        check_mountpoints $SNOW_ROOT
    else
        mkdir -p $SNOW_ROOT
        mkdir -p $SNOW_HOME
        bkp /etc/fstab
        echo "$NFS_SERVER:$SNOW_ROOT $SNOW_ROOT    nfs    rw,tcp,bg,hard,intr,async,nodev,nosuid,defaults 0 0" >> /etc/fstab
        echo "$NFS_SERVER:$SNOW_HOME $SNOW_HOME    nfs    rw,tcp,bg,hard,intr,async,nodev,nosuid,defaults 0 0" >> /etc/fstab
        mount $SNOW_ROOT
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
    if [[ ! -f  ${SNOW_ROOT}/eula.txt ]]; then
        echo "[E] The local sNow! tools repository is corrupted. Please, test your connection to GitHub."
    fi
    more  ${SNOW_ROOT}/eula.txt
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
setup_snow_env
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
