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
    cluster=$(jq ".compute.${HOSTNAME}.cluster" ${SNOW_ETC}/nodes.json |sed -e 's|"||g')
    if [[ ! -e $SNOW_SRV/deploy_files/etc/ganglia/gmond_${cluster}.conf ]]; then 
        warning_msg "Ganglia configuration not found. Using default values." 
        /usr/sbin/gmond -t > $SNOW_SRV/deploy_files/etc/ganglia/gmond_${cluster}.conf
        sed -i "s|name = \"unspecified\"|name = \"${cluster}\"|g" $SNOW_SRV/deploy_files/etc/ganglia/gmond_${cluster}.conf
    fi
    cp -p $SNOW_SRV/deploy_files/etc/ganglia/gmond_${cluster}.conf /etc/ganglia/gmond.conf
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
