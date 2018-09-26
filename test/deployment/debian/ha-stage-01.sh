#!/bin/bash
###
### Contents Debian Stretch automatic deployment of sNow! in HA to conduct CI
### Copyright (C) 2018  Jordi Blasco <jordi.blasco@hpcnow.com>
###
### This program is free software: you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation, either version 3 of the License, or
### (at your option) any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
###
### You should have received a copy of the GNU General Public License
### along with this program.  If not, see <http://www.gnu.org/licenses/>.
### 

### BeeGFS Installation
apt install linux-headers-$(uname -r) -y
apt install beegfs-client beegfs-helperd -y
echo "/beegfs /etc/beegfs/beegfs-client.conf" > /etc/beegfs/beegfs-mounts.conf
mkdir -p /beegfs
/opt/beegfs/sbin/beegfs-setup-client -m beegfs01
sleep 5
systemctl start beegfs-helperd
systemctl start beegfs-client
mkdir -p /beegfs/snow/testing/{sNow,home}
echo "
/beegfs/snow/testing/home                     /home          none  noauto,x-systemd.automount,x-systemd.device-timeout=60,_netdev,bind,x-systemd.requires=/beegfs/snow/testing/home   0 0
/beegfs/snow/testing/sNow                     /sNow          none  noauto,x-systemd.automount,x-systemd.device-timeout=60,_netdev,bind,x-systemd.requires=/beegfs/snow/testing/sNow 0 0
" >> /etc/fstab
mount /home
mount /sNow

### sNow! Installation
cd /root/snow-ci/debian
if [[ ! -e /sNow/snow-tools/etc/snow.conf ]]; then
    cd /sNow/
    git clone http://bitbucket.org/hpcnow/snow-tools.git
fi
cd /sNow/snow-tools
export NFS_SERVER=beegfs01
export SNOW_EULA=accepted
./install.sh

### sNow! Configuration
if [[ ! -e /sNow/snow-tools/etc/snow.conf ]]; then
    cp -p /root/snow-ci/debian/ha-snow.conf /sNow/snow-tools/etc/snow.conf
    cp -p /root/snow-ci/debian/active-domains.conf /sNow/snow-tools/etc/
    source /etc/profile.d/snow.sh
    snow init
else
    source /etc/profile.d/snow.sh
    snow init force
fi

### Enable stage 02
#systemctl enable first_boot
#rm -f /usr/local/first_boot/ha-stage-01.sh
#cp -p /root/snow-ci/debian/ha-stage-02.sh /usr/local/first_boot/

### Reboot the system with new kernel and configuration
reboot
