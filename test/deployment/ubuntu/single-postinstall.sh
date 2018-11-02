#!/bin/bash
###
### Contents Ubuntu 18.04 LTS (Bionic) automatic deployment of sNow! in HA to conduct CI
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
snow_release="milestone-2.0.0"
### sNow! Installation
if [[ ! -e /sNow ]]; then
    mkdir /sNow
fi
rm -fr /sNow/* /sNow/.git /sNow/.gitignore
git clone https://github.com/HPCNow/sNow.git -b ${snow_release} /sNow/
if [[ -e /sNow/etc/snow.conf ]]; then
    cp -p /sNow/test/deployment/ubuntu/netplan_snow02 /etc/netplan/01-netcfg.yaml
else
    cp -p /sNow/test/deployment/ubuntu/netplan_snow01 /etc/netplan/01-netcfg.yaml
fi

cat /sNow/test/deployment/ubuntu/hosts >> /etc/hosts

### Enable First Boot actions
cp -p /sNow/test/deployment/ubuntu/first_boot.service /lib/systemd/system/
cp -p /sNow/test/deployment/ubuntu/first_boot /usr/local/bin/first_boot
chmod 700 /usr/local/bin/first_boot
mkdir -p /usr/local/first_boot
chmod 700 /usr/local/first_boot
chown root /usr/local/first_boot

### Enable stage 01
cp -p /sNow/test/deployment/ubuntu/single-stage-01.sh /usr/local/first_boot/
chmod 700 /usr/local/first_boot/single-stage-01.sh
systemctl enable first_boot
netplan apply
