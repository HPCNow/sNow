#!/bin/bash
# This is the sNow! deployment Post Install Script
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow

#set -xv
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
# sNow! paths
# SNOW_HOME and SNOW_SOFT can be setup in different paths
SNOW_PATH=/sNow
SNOW_TOOL=$SNOW_PATH/snow-tools
SNOW_CONF=$SNOW_PATH/snow-configspace
readonly CONFIG_FILE=${SNOW_TOOL}/etc/snow.conf

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

if [[ -f ${CONFIG_FILE} ]]; then
    echo "Loading sNow! configuration ..."
    source ${CONFIG_FILE}
else
    echo "sNow! config file NOT found!!!"
fi

if [[ -f ${SNOW_TOOL}/share/common.sh ]]; then
    LOGFILE=/root/snow-postinstall.log
    if [[ ! -f ${LOGFILE} ]]; then
        touch ${LOGFILE}
    fi
    RETAIN_NUM_LINES=10
    source ${SNOW_TOOL}/share/common.sh
    logsetup
    get_os_distro
    architecture_identification
fi

readonly TEMPLATE=${1:-$DEFAULT_TEMPLATE}
readonly TEMPLATE_PATH=${SNOW_CONF}/boot/templates/$TEMPLATE

if [[ -f ${TEMPLATE_PATH}/config ]]; then
    echo "Loading $TEMPLATE configuration ..."
    source ${TEMPLATE_PATH}/config
else
    echo "Config file not found"
fi

LAST_WORKER_INDEX=$(($WORKER_COUNT - 1))

function setup_software()
{
    PKG_LIST=${TEMPLATE_PATH}/packages
    add_repos ${TEMPLATE_PATH}/repos
    pkgs=$(cat ${PKG_LIST} | grep -v "^#" | tr '\n' ' ')
    install_software "$pkgs"
} 1>>$LOGFILE 2>&1

setup_software         && error_check 0 'Stage  1/12: Software installed ' || error_check 1 'Stage 1/12: Software installed ' &
spinner $!             'Stage  1/12: Installing Software '
setup_networkfs        && error_check 0 'Stage  2/12: Distributed filesystem setup ' || error_check 1 'Stage 2/12: Distributed filesystem setup ' &
spinner $!             'Stage  2/12: Setting distributed filesystem '
setup_ssh              && error_check 0 'Stage  3/12: SSH service and sNow! users created ' || error_check 1 'Stage 3/12: SSH service and sNow! users created ' &
spinner $!             'Stage  3/12: Creating SSH service and sNow! users '
setup_env              && error_check 0 'Stage  4/12: User Environment configured ' || error_check 1 'Stage 4/12: User Environment configuration ' &
spinner $!             'Stage  4/12: Configuring User Environment '
install_lmod           && error_check 0 'Stage  5/12: Lmod install ' || error_check 1 'Stage 5/12: Lmod install ' &
spinner $!             'Stage  5/12: Installing Lmod '
install_easybuild      && error_check 0 'Stage  6/12: EasyBuild install ' || error_check 1 'Stage 6/12: EasyBuild install ' &
spinner $!             'Stage  6/12: Installing EasyBuild '
setup_ldap_client      && error_check 0 'Stage  7/12: LDAP client setup ' || error_check 1 'Stage 7/12: LDAP client setup ' &
spinner $!             'Stage  7/12: Setting LDAP client '
setup_ganglia_client   && error_check 0 'Stage  8/12: Ganglia client setup ' || error_check 1 'Stage 8/12: Ganglia client setup ' &
spinner $!             'Stage  8/12: Setting Ganglia client '
setup_workload_client  && error_check 0 'Stage  9/12: Workload Manager setup ' || error_check 1 'Stage 9/12: Workload Manager setup ' &
spinner $!             'Stage  9/12: Setting Workload Manager '
setup_syslog_client    && error_check 0 'Stage 10/12: Syslog client setup ' || error_check 1 'Stage 10/12: Syslog client setup ' &
spinner $!             'Stage 10/12: Setting syslog client '
setup_ntp_client       && error_check 0 'Stage 11/12: NTP client setup ' || error_check 1 'Stage 11/12: NTP client setup ' &
spinner $!             'Stage 11/12: Setting NTP client '

if [[ -z ${DOCKER_VERSION} ]]; then
    setup_docker_swarm_worker && error_check 0 'Stage 12/12 : sNow! Docker Swarm worker installation ' || error_check 1 'Stage 12/12 : sNow! Docker Swarm worker installation ' &
    spinner $!         'Stage 12/12 : sNow! Docker Swarm worker installation '
fi
if [[ -z ${OPENNEBULA_VERSION} ]]; then
    setup_opennebula   && error_check 0 'Stage 12/12 : sNow! OpenNebula installation ' || error_check 1 'Stage 12/12 : sNow! OpenNebula installation ' &
    spinner $!         'Stage 12/12 : sNow! OpenNebula installation '
fi

hooks ${TEMPLATE_PATH}
first_boot_hooks ${TEMPLATE_PATH}
end_msg
