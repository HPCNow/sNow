#!/bin/bash
#
# This file contains the common functions used by sNow! Command Line Interface
# Copyright (C) 2008 Jordi Blasco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# sNow! Cluster Suite is an opensource project developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website: www.hpcnow.com/snow
#
function setup_syslog_client()
{
    SNOW_SYSLOG_SERVER=$(gawk '{if($2 ~ /syslog/){print $4}}' $SNOW_ROOT/etc/domains.conf)
    SYSLOG_SERVER="${SITE_SYSLOG_SERVER:-$SNOW_SYSLOG_SERVER}"
    if  [[ ! -z "${SYSLOG_SERVER}" ]]; then 
        install_software "rsyslog"
        if [[ -e ${SNOW_SRV}/deploy_files/etc/rsyslog.d/50-default.conf ]]; then 
            cp -p ${SNOW_SRV}/deploy_files/etc/rsyslog.d/50-default.conf /etc/rsyslog.d/50-default.conf
        else
            mkdir -p ${SNOW_SRV}/deploy_files/etc/rsyslog.d
            echo "*.*                         @@${SYSLOG_SERVER}:514" >> /etc/rsyslog.d/50-default.conf
            cp -p /etc/rsyslog.d/50-default.conf ${SNOW_SRV}/deploy_files/etc/rsyslog.d/50-default.conf
        fi
    fi
} 1>>$LOGFILE 2>&1
