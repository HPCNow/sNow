#!/bin/bash
###
### Contents Debian Stretch automatic deployment of sNow! to conduct CI
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
snow_release="opennebula"
### sNow! Installation
cd /root/snow-ci/debian
cd /sNow/
git clone https://github.com/HPCNow/sNow.git -b ${snow_release}
cd /sNow/snow-tools
export SNOW_EULA=accepted
./install.sh ${snow_release}
#apt install linux-headers-$(uname -r) -y

### sNow! Configuration
cp -p /root/snow-ci/debian/single-snow.conf ${SNOW_ETC}/snow.conf
cp -p /root/snow-ci/debian/active-domains.conf ${SNOW_ETC}/
source /etc/profile.d/snow.sh
snow init

### Enable stage 02
#systemctl enable first_boot
#rm -f /usr/local/first_boot/stage-01.sh
#cp -p /root/snow-ci/debian/stage-02.sh /usr/local/first_boot/

### Reboot the system with new kernel and configuration
reboot
