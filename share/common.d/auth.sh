#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function setup_ldap_client()
{
    if [[ -f $SNOW_CONF/system_files/etc/sssd/sssd.conf.cn ]]; then
        cp -p $SNOW_CONF/system_files/etc/sssd/sssd.conf.cn /etc/sssd/sssd.conf
        chown root:root /etc/sssd/sssd.conf
        chmod 600 /etc/sssd/sssd.conf
        systemctl enable sssd.service
        systemctl start sssd.service
    fi
} 1>>$LOGFILE 2>&1
