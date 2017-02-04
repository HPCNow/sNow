#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function setup_ldap_client()
{
    case $OS in
        debian|ubuntu)
            pkgs="libpam-ldap sssd-ldap sssd-tools sssd-common"
        ;;
        rhel|redhat|centos)
            pkgs="sssd-common sssd-client sssd-ldap"
        ;;
        suse|sle[sd]|opensuse)
            pkgs="sssd"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
    if [[ -f $SNOW_CONF/system_files/etc/sssd/sssd.conf ]]; then
        cp -p $SNOW_CONF/system_files/etc/sssd/sssd.conf /etc/sssd/sssd.conf
        chown root:root /etc/sssd/sssd.conf
        chmod 600 /etc/sssd/sssd.conf
        systemctl enable sssd.service
        systemctl start sssd.service
    fi
} 1>>$LOGFILE 2>&1
