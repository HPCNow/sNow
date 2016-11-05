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
readonly CONFIG_FILE=${SNOW_TOOL}/etc/snow.conf

if [[ -f ${CONFIG_FILE} ]]; then
    echo "Loading sNow! configuration ..."
    source ${CONFIG_FILE}
else
    echo "sNow! config file NOT found!!!"
fi

if [[ -f ${SNOW_TOOL}/share/common.sh ]]; then
    LOGFILE=/root/post-install.log
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
hooks ${TEMPLATE_PATH} 
first_boot_hooks ${TEMPLATE_PATH}
end_msg