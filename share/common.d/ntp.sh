#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function setup_ntp_client()
{
    SNOW_NTP_SERVER=$(gawk '{if($2 ~ /proxy/){print $4}}' $SNOW_TOOL/etc/domains.conf)
    if  [[ ! -z "$SNOW_NTP_SERVER" && ! -z "$SITE_NTP_SERVER" ]]; then 
        NTP_SERVER=$SNOW_NTP_SERVER
    else
        NTP_SERVER="${SITE_NTP_SERVER:-$SNOW_NTP_SERVER}"
    fi
    if  [[ ! -z "$NTP_SERVER" ]]; then 
        install_software "ntp"
        if [[ -e /sNow/snow-configspace/system_files/etc/ntp.conf ]]; then 
            cp -p /sNow/snow-configspace/system_files/etc/ntp.conf /etc/
        else
            cp -p /sNow/snow-tools/etc/config_template.d/ntp_client/ntp.conf /sNow/snow-configspace/system_files/etc/ntp.conf
            sed -i "s/__NTP_SERVER__/$NTP_SERVER/g" /sNow/snow-configspace/system_files/etc/ntp.conf
            chmod 644 /sNow/snow-configspace/system_files/etc/ntp.conf
            cp -p /sNow/snow-configspace/system_files/etc/ntp.conf /etc/
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
