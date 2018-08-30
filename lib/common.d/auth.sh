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

function setup_ldap_client()
{
    case $OS in
        debian|ubuntu)
            #pkgs="libpam-ldap sssd-ldap sssd-tools sssd-common"
            pkgs="sssd-ldap sssd-tools sssd-common"
            echo "session required          pam_mkhomedir.so skel=/etc/skel umask=0077" >> /etc/pam.d/common-session
        ;;
        rhel|redhat|centos)
            pkgs="sssd sssd-common sssd-client sssd-ldap"
            sed -i "s|USEMKHOMEDIR=no|USEMKHOMEDIR=yes|g" /etc/sysconfig/authconfig
            authconfig --enablemkhomedir --update
        ;;
        suse|sle[sd]|opensuse)
            pkgs="sssd"
            echo "session required          pam_mkhomedir.so skel=/etc/skel umask=0077" >> /etc/pam.d/common-session
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
    if [[ -f $SNOW_SRV/system_files/etc/sssd/sssd.conf ]]; then
        cp -p $SNOW_SRV/system_files/etc/sssd/sssd.conf /etc/sssd/sssd.conf
        chown root:root /etc/sssd/sssd.conf
        chmod 600 /etc/sssd/sssd.conf
        systemctl enable sssd.service
        systemctl start sssd.service
    fi
} 1>>$LOGFILE 2>&1
