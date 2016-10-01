#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function setup_ganglia_client()
{
    if [[ -f $SNOW_CONF/system_files/etc/ganglia/gmond.conf ]]; then
        cp -p $SNOW_CONF/system_files/etc/ganglia/gmond.conf /etc/ganglia/gmond.conf
        chown root:root /etc/ganglia/gmond.conf
        chmod 640 /etc/ganglia/gmond.conf
        systemctl enable gmond.service
        systemctl start gmond.service
    fi
} 1>>$LOGFILE 2>&1
