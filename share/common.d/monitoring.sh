#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function setup_ganglia_client()
{
    case $OS in
        debian|ubuntu)
            pkgs="ganglia-monitor"
        ;;
        rhel|redhat|centos)
            pkgs="ganglia-gmond"
        ;;
        suse|sle[sd]|opensuse)
            pkgs="ganglia-gmond"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
    if [[ ! -e $SNOW_CONF/system_files/etc/ganglia/gmond.conf ]]; then 
        chroot ${prefix} /usr/sbin/gmond -t > $SNOW_CONF/system_files/etc/ganglia/gmond.conf
        sed -i 's|name = "unspecified"|name = "sNow!"|g' $SNOW_CONF/system_files/etc/ganglia/gmond.conf
    fi
    cp -p $SNOW_CONF/system_files/etc/ganglia/gmond.conf /etc/ganglia/gmond.conf
    chown root:root /etc/ganglia/gmond.conf
    chmod 640 /etc/ganglia/gmond.conf
    systemctl enable gmond.service
    systemctl start gmond.service
} 1>>$LOGFILE 2>&1
