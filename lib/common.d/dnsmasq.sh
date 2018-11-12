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

function setup_dnsmasq()
{
    case $OS in
        debian|ubuntu)
            pkgs="ipmitool openipmi freeipmi nfs-common dnsmasq"
        ;;
        rhel|redhat|centos)
            pkgs="ipmitool openipmi freeipmi nfs-common dnsmasq"
        ;;
        suse|sle[sd]|opensuse)
            pkgs="ipmitool openipmi freeipmi nfs-common dnsmasq"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"

    # setup dnsmasq config file
    if [[ ! -f ${SNOW_ETC}/dnsmasq.conf ]]; then
        bkp /etc/dnsmasq.conf
        last_ip=$(last_ip_in_range ${NET_COMP[2]}/${NET_COMP[4]})
        echo "
        interface=$DHCP_NIC
        # Gateway
        dhcp-option=3,${NET_COMP[1]}
        # DNS
        dhcp-option=6,$SNOW_DNS_SERVER,$DNS_SERVERS
        # Domain Name
        dhcp-option=15,$DOMAIN
        # 0.0.0.0 Means to reference self for this option
        dhcp-range=$DHCP_NIC,${NET_COMP[2]},${last_ip},24h
        dhcp-boot=pxelinux.0
        dhcp-match=set:efi-x86_64,option:client-arch,7
        dhcp-boot=tag:efi-x86_64,grubx64.efi
        addn-hosts=/etc/static_hosts
        dhcp-sequential-ip
        clear-on-reload
        enable-tftp
        tftp-root=${SNOW_SRV}/tftp
        " > ${SNOW_ETC}/etc/dnsmasq.conf
        ln -sf ${SNOW_ETC}/dnsmasq.conf /etc/dnsmasq.conf
    else
        ln -sf ${SNOW_ETC}/dnsmasq.conf /etc/dnsmasq.conf
    fi

    # Setup ethers file (macaddress table)
    if [[ ! -e $SNOW_SRV/deploy_files/etc/ethers ]]; then
        touch /etc/ethers
        cp -p /etc/ethers $SNOW_SRV/deploy_files/etc/ethers
    else
        ln -sf $SNOW_SRV/deploy_files/etc/ethers /etc/ethers
    fi

    # Setup host list managed by sNow!
    if [[ ! -e $SNOW_SRV/deploy_files/etc/static_hosts ]]; then
        touch /etc/static_hosts
        cp -p /etc/static_hosts $SNOW_SRV/deploy_files/etc/static_hosts
    else
        ln -sf $SNOW_SRV/deploy_files/etc/static_hosts /etc/static_hosts
    fi

    # Enable and start dnsmasq
    systemctl enable dnsmasq
    systemctl start dnsmasq

} 1>>$LOGFILE 2>&1
