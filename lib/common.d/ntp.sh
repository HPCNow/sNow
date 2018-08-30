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
function setup_ntp_client()
{
    SNOW_NTP_SERVER=$(gawk '{if($2 ~ /proxy/){print $4}}' $SNOW_ROOT/etc/domains.conf)
    if  [[ ! -z "$SNOW_NTP_SERVER" && ! -z "$SITE_NTP_SERVER" ]]; then 
        NTP_SERVER=$SNOW_NTP_SERVER
    else
        NTP_SERVER="${SITE_NTP_SERVER:-$SNOW_NTP_SERVER}"
    fi
    if  [[ ! -z "$NTP_SERVER" ]]; then 
        install_software "ntp"
        if [[ -e ${SNOW_SRV}/deploy_files/etc/ntp.conf ]]; then 
            cp -p ${SNOW_SRV}/deploy_files/etc/ntp.conf /etc/
        else
            cp -p ${SNOW_ETC}/config_template.d/ntp_client/ntp.conf ${SNOW_SRV}/deploy_files/etc/ntp.conf
            sed -i "s/__NTP_SERVER__/$NTP_SERVER/g" ${SNOW_SRV}/deploy_files/etc/ntp.conf
            chmod 644 ${SNOW_SRV}/deploy_files/etc/ntp.conf
            cp -p ${SNOW_SRV}/deploy_files/etc/ntp.conf /etc/
        fi
        case $OS in
            debian|ubuntu)
                systemctl enable ntp
            ;;
            rhel|redhat|centos)
                systemctl enable ntpd
            ;;
            suse|sle[sd]|opensuse)
                systemctl enable ntpd
            ;;
            *)
                warning_msg "This distribution is not supported. NTP client may not work."
            ;;
        esac
    fi
} 1>>$LOGFILE 2>&1
