#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function setup_syslog_client()
{
    SNOW_SYSLOG_SERVER=$(gawk '{if($2 ~ /syslog/){print $4}}' $SNOW_TOOL/etc/domains.conf)
    SYSLOG_SERVER="${SITE_SYSLOG_SERVER:-$SNOW_SYSLOG_SERVER}"
    if  [[ ! -z "${SYSLOG_SERVER}" ]]; then 
        install_software "rsyslog"
        if [[ -e ${SNOW_CONF}/system_files/etc/rsyslog.d/50-default.conf ]]; then 
            cp -p ${SNOW_CONF}/system_files/etc/rsyslog.d/50-default.conf /etc/rsyslog.d/50-default.conf
        else
            mkdir -p ${SNOW_CONF}/system_files/etc/rsyslog.d
            echo "*.*                         @@${SYSLOG_SERVER}:514" >> /etc/rsyslog.d/50-default.conf
            cp -p /etc/rsyslog.d/50-default.conf ${SNOW_CONF}/system_files/etc/rsyslog.d/50-default.conf
        fi
    fi
} 1>>$LOGFILE 2>&1
