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
#apt install linux-headers-$(uname -r) -y

snow_release="milestone-2.0.0"
source /etc/profile
### sNow! Installation
cp -p /sNow/test/deployment/ubuntu/single-snow.conf /sNow/etc/snow.conf
if [[ -e /sNow/etc/snow.conf ]]; then
    cp -p /sNow/test/deployment/ubuntu/netplan_snow02 /etc/netplan/01-netcfg.yaml
else
    cp -p /sNow/test/deployment/ubuntu/netplan_snow01 /etc/netplan/01-netcfg.yaml
fi
export SNOW_EULA=accepted
cd /sNow
./install.sh ${snow_release}

apt update
apt upgrade -y
### sNow! Configuration
cp -p /sNow/test/deployment/ubuntu/single-snow.conf /sNow/etc/snow.conf
cp -p /sNow/test/deployment/ubuntu/active-domains.conf /sNow/etc/
source /etc/profile
snow init

### Enable stage 02
#systemctl enable first_boot
#rm -f /usr/local/first_boot/stage-01.sh
#cp -p /sNow/test/deployment/ubuntu//stage-02.sh /usr/local/first_boot/

### Reboot the system with new kernel and configuration
reboot
