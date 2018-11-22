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

### sNow! Domain Template Download
snow update template

### Enable firewall
snow update firewall

### Deploy Domains
snow deploy deploy01
snow deploy ldap01
snow deploy syslog01
snow deploy proxy01
snow deploy slurmdb01
snow deploy slurm01
snow deploy monitor01
snow deploy login01
snow deploy swarm01
snow deploy swarm02
snow deploy one01

### update the memory used by each domain in order to fit the testing node
sed -i "s|2048|512|g" /sNow/etc/domains/*.cfg

### Boot Domains
snow boot domains

#sleep 120
### Deploy golden node
#snow deploy bdw01 centos-7.4-default
#sleep 600

### Generate Stateless Image
#snow clone node bdw01 centos-stateless stateless "CentOS 7.4 Stateless Image"

### Generate Stateless Image
#snow clone node bdw01 centos-ssi-nfs nfsroot "CentOS 7.4 Single System Image - NFSROOT"

### Enable stage 03
#systemctl enable first_boot
#rm -f /usr/local/first_boot/stage-02.sh
#cp -p /sNow/test/deployment/ubuntu/single-stage-03.sh /usr/local/first_boot/
