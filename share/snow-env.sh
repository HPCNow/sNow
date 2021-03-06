#!/bin/bash
# This is the sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website: www.hpcnow.com/snow
#
#set -xv
readonly RETAIN_NUM_LINES=10
# Load the configuration
SNOW_PATH=/sNow
SNOW_HOME=${SNOW_PATH}/home
SNOW_SOFT=${SNOW_PATH}/easybuild
SNOW_CONF=${SNOW_PATH}/snow-configspace
SNOW_TOOL=${SNOW_PATH}/snow-tools
readonly CONFIG_FILE=${SNOW_TOOL}/etc/snow.conf
readonly ENTERPRISE_EXTENSIONS=${SNOW_TOOL}/share/enterprise_extensions.sh
readonly SNOW_DOMAINS=${SNOW_TOOL}/etc/domains.conf
readonly SNOW_ACTIVE_DOMAINS=${SNOW_TOOL}/etc/active-domains.conf
declare -A CLUSTERS
HAS_EE=false

if [[ -f ${CONFIG_FILE} ]]; then
    source ${CONFIG_FILE}
    export PDSH_RCMD_TYPE
fi

if [[ -f ${SNOW_TOOL}/share/common.sh ]]; then
    source ${SNOW_TOOL}/share/common.sh
    logsetup
    get_os_distro
    architecture_identification
fi

if [[ -f ${SNOW_DOMAINS} ]]; then
    readonly SELF_ACTIVE_DOMAINS=$(cat ${SNOW_DOMAINS} | grep -v ^# | gawk '{if($2 !~ /^snow$/){print $1}}')
fi

if [[ -f ${ENTERPRISE_EXTENSIONS} ]]; then
    source ${ENTERPRISE_EXTENSIONS}
    HAS_EE=true
fi

if ! [[ -d ${SNOW_PATH}/log ]]; then
    mkdir ${SNOW_PATH}/log
fi

