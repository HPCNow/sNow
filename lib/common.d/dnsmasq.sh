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
        addn-hosts=/etc/static_hosts
        dhcp-sequential-ip
        clear-on-reload
        enable-tftp
        tftp-root=/srv/tftp
        " > ${SNOW_ETC}/etc/dnsmasq.conf
        ln -sf ${SNOW_ETC}/dnsmasq.conf /etc/dnsmasq.conf
    else
        ln -sf ${SNOW_ETC}/dnsmasq.conf /etc/dnsmasq.conf
    fi
    mkdir -p ${SNOW_VAR}/boot/{images,templates}



    # Setup DNSMASQ
    if [[ ! -e $SNOW_SRV/system_files/etc/ethers ]]; then
        touch ${prefix}/etc/ethers
        cp -p ${prefix}/etc/ethers $SNOW_SRV/system_files/etc/ethers
    else
        cp -p $SNOW_SRV/system_files/etc/ethers ${prefix}/etc/ethers
    fi

    cp -p $SNOW_SRV/system_files/etc/static_hosts ${prefix}/etc/static_hosts
    cp -p $SNOW_ROOT/etc/config_template.d/dhcp/fishermac ${prefix}/usr/local/bin/

    # DNS Client Setup
    if [[ -e $SNOW_SRV/system_files/etc/resolv.conf ]]; then
        echo "search $DOMAIN ${DNS_SEARCH_LIST}" > ${prefix}/etc/resolv.conf
        if [[ ! -z "$SITE_DNS_SERVER" ]]; then
            SITE_DNS=$(echo $SITE_DNS_SERVER | tr ',' '\n' | gawk '{print "nameserver "$1}')
            echo "$SITE_DNS" >> ${prefix}/etc/resolv.conf
        fi
        if [[ ! -z "$DNS_SERVERS" ]]; then
            PUBLIC_DNS=$(echo $DNS_SERVERS | tr ',' '\n' | gawk '{print "nameserver "$1}')
            echo "$PUBLIC_DNS" >> ${prefix}/etc/resolv.conf
        fi
    fi

    # Install and setup sNow! deploy system
    if [[ ! -f $SNOW_SRV/boot/templates/postconfig.sh ]]; then
        if [[ ! -d $SNOW_SRV ]]; then
            mkdir $SNOW_SRV
        fi
        cp -pr $SNOW_ROOT/etc/config_template.d/boot $SNOW_SRV/
        SNOW_PROXY_SERVER=$(gawk '{if($2 ~ /proxy/){print $4}}' $SNOW_ROOT/etc/domains.conf)
        if  [[ ! -z "$SNOW_PROXY_SERVER" && ! -z "$SITE_PROXY_SERVER" ]]; then
            PROXY_SERVER=$SNOW_PROXY_SERVER
            PROXY_PORT=8080
        else
            PROXY_SERVER="${SITE_PROXY_SERVER:-$SNOW_PROXY_SERVER}"
            PROXY_PORT="${SITE_PROXY_PORT:-8080}"
        fi
        for tmpl in $(find $SNOW_SRV/boot/templates/ -name "*-*" -type d | sed -e "s|$SNOW_SRV/boot/templates/||g"); do
            for file in $(find $SNOW_SRV/boot/templates/$tmpl -type f); do
                sed -i "s|__DEFAULT_TEMPLATE__|$tmpl|g" $file
                sed -i "s|__LANG__|$LANG|g" $file
                sed -i "s|__KEYMAP__|$KEYMAP|g" $file
                sed -i "s|__TIMEZONE__|$TIMEZONE|g" $file
                sed -i "s|__MASTER_PASSWORD__|$MASTER_PASSWORD|g" $file
                sed -i "s|__NFS_SERVER__|$NFS_SERVER|g" $file
                sed -i "s|__SNOW_HOME__|$SNOW_HOME|g" $file
                sed -i "s|__PROXY_SERVER__|$PROXY_SERVER|g" $file
                sed -i "s|__PROXY_PORT__|$PROXY_PORT|g" $file
                sed -i "s|__TFTP_SERVER__|$TFTP_SERVER|g" $file
            done
        done
    fi

    # HPCNow repos
    if [[ ! -e $SNOW_SRV/system_files/etc/repos ]]; then
        mkdir -p $SNOW_SRV/system_files/etc/repos
        cp -pr $SNOW_ROOT/etc/config_template.d/repos/* $SNOW_SRV/system_files/etc/repos/
    fi

    # Download linux kernels to boot OS from PXE defined in $SNOW_ROOT/etc/config_template.d/boot/templates/pxe_kernels.conf
    while read line; do
        download_path=$(echo $line | gawk '{print $2}')
        download_url=$(echo $line | gawk '{print $1}')
        if [[ ! -e ${download_path} ]]; then
            mkdir -p ${download_path}
        fi
        download ${download_url} ${download_path}
    done < $SNOW_ROOT/etc/config_template.d/boot/templates/pxe_kernels.conf

    systemctl enable dnsmasq
    systemctl start dnsmasq
} 1>>$LOGFILE 2>&1
