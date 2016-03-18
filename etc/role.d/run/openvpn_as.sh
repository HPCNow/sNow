#!/bin/bash
# This is the sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

# Get the public IP
curl ifconfig.me > /tmp/ip.txt 2> /dev/null

# Download the OpenVPN AS package
cd /tmp
wget -c http://swupdate.openvpn.org/as/openvpn-as-2.0.25-Debian8.amd_64.deb

# Install the package
dpkg -i openvpn-as-2.0.25-Debian8.amd_64.deb

# Update the OpenVPN user password
echo "openvpn:$MASTERPWD" | chpasswd

# Install the domain
if [[ "$OPENVPNAS_RECONFIGURE" == "true" ]]; then
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
else
    systemctl stop openvpnas.service
    systemctl enable openvpnas.service
fi

echo "Visit https://$(hostname -f):943/admin and follow the instructions"
