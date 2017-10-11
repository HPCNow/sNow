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
    cluster=$(jq ".compute.${HOSTNAME}.cluster" ${SNOW_TOOL}/etc/nodes.json |sed -e 's|"||g')
    if [[ ! -e $SNOW_CONF/system_files/etc/ganglia/gmond.${cluster}.conf ]]; then 
        /usr/sbin/gmond -t > $SNOW_CONF/system_files/etc/ganglia/gmond.conf
        sed -i 's|name = "unspecified"|name = "sNow"|g' $SNOW_CONF/system_files/etc/ganglia/gmond.conf
    fi
    cp -p $SNOW_CONF/system_files/etc/ganglia/gmond_${cluster}.conf /etc/ganglia/gmond.conf
    chown root:root /etc/ganglia/gmond.conf
    chmod 640 /etc/ganglia/gmond.conf
    case $OS in
        debian|ubuntu)
            systemctl enable ganglia-monitor.service
            systemctl start ganglia-monitor.service
        ;;
        rhel|redhat|centos)
            systemctl enable gmond.service
            systemctl start gmond.service
        ;;
        suse|sle[sd]|opensuse)
            systemctl enable gmond.service
            systemctl start gmond.service
        ;;
        *)
            warning_msg "This distribution is not supported. Ganglia may not work."
        ;;
    esac
} 1>>$LOGFILE 2>&1
