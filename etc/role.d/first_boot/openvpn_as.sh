#!/bin/bash
# This script is part of sNow! Tools
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

# Get the public IP
curl ifconfig.me > /tmp/ip.txt 2> /dev/null

# Install the package
dpkg -i /root/openvpn-as-2.0.25-Debian8.amd_64.deb

# Update the OpenVPN user password
echo 'openvpn:__MASTER_PASSWORD__' | chpasswd

# Install the domain
if [[ "$OPENVPNAS_RECONFIGURE" == "__OPENVPNAS_RECONFIGURE__" ]]; then
    systemctl stop openvpnas.service
    cp -p /usr/local/openvpn_as/etc/db/config.db /usr/local/openvpn_as/etc/db/config.db.bak
    /usr/local/openvpn_as/scripts/sqlite3 /usr/local/openvpn_as/etc/db/config.db .dump > /usr/local/openvpn_as/scripts/configdb.txt
    for PubIP in $(cat /tmp/ip.txt)
    do
       sed -i "/host.name/s/[0-9]\+\..*[0-9]\+/${PubIP}/" /usr/local/openvpn_as/scripts/configdb.txt
    done
    rm /usr/local/openvpn_as/etc/db/config.db
    /usr/local/openvpn_as/scripts/sqlite3 < /usr/local/openvpn_as/scripts/configdb.txt /usr/local/openvpn_as/etc/db/config.db
    systemctl enable openvpnas.service
    systemctl start openvpnas.service
else
    systemctl enable openvpnas.service
    systemctl start openvpnas.service
fi

systemctl disable openvpn_as_boot

echo "OpenVPN Access Server Installed. Next steeps to be completed:"
echo "  1. Visit https://$(hostname -f):943/admin"
echo "  2. Follow the instructions available in this GUI"
echo "  3. Visit https://$(hostname -f):943 to setup your OpenVPN client"

echo "Rebooting the system in 30 seconds"
sleep 30
reboot
