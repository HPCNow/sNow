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

### Fetching CI setup
cd /root
git clone https://github.com/HPCNow/snow-ci

### sNow Servers Configuration
cd /root/snow-ci/debian
if [[ -e /sNow/snow-tools/etc/snow.conf ]]; then
    cp -p interfaces_snow02 /etc/network/interfaces 
else
    cp -p interfaces_snow01 /etc/network/interfaces 
fi
cat ./hosts >> /etc/hosts

### BeeGFS Repositories
cd /etc/apt/sources.list.d/
wget https://www.beegfs.io/release/latest-stable/dists/beegfs-deb9.list
wget -q https://www.beegfs.io/release/latest-stable/gpg/DEB-GPG-KEY-beegfs -O- | apt-key add -
apt update
apt upgrade -y

### Enable First Boot actions
cp -p /root/snow-ci/debian/first_boot.service /lib/systemd/system/
cp -p /root/snow-ci/debian/first_boot /usr/local/bin/first_boot
chmod 700 /usr/local/bin/first_boot
mkdir -p /usr/local/first_boot
chmod 700 /usr/local/first_boot
chown root /usr/local/first_boot

### Enable stage 01
cp -p /root/snow-ci/debian/ha-stage-01.sh /usr/local/first_boot/
chmod 700 /usr/local/first_boot/ha-stage-01.sh
systemctl enable first_boot
