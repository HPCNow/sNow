---
title: Backup
tags: [backup]
summary: "This section explains how to setup the backup of sNow!"
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_admin_backup.html
folder: mydoc
---
As you know sNow! consists on one or more sNow! nodes which run different domains or virtual machines. The backup strategy may vary depending on your configuration. A simple approach would consist of the following steps (please do not use the following commands blindly as are potentially destructive if you have a different configuration):

1. Create the backup directory
For the purpose of this guide we are going to backup under /sNow/backup/201611. Obviously, after doing the backup you need to save all the data generated there in a safe place which meets the security rules of your company.
```
mkdir -p /sNow/backup/201611
```
2. Backup configuration of the sNow! nodes.
Backup the installed package list and the /etc/ directory of each sNow node. We assume here we have only snow01.
```    
dpkg --get-selections | awk ' { print $1 } ' | xargs > /sNow/backup/201611/package-list.txt
cd /etc
tar -zcvf /sNow/backup/201611/etc.tar.gz *
```
3. Backup of the /sNow filesystem
You will need to backup the /sNow filesystem contents. To do that:
```
cd /sNow
tar --exclude=backup/* -zcvf /sNow/backup/201611/sNow.tar.gz *
```
4. VM backup
It's time to backup the VMs. To do that you will create a snapshot and then dd it to a file.
Obtaining a list of the working VMs (if you have VMs that are not powered on and you need to backup then please take it into consideration):
```
snow list| egrep -v "Name|Domain-0"|gawk '{print $1}'
```
Creating the snapshots:
```
for i in `snow list| egrep -v "Name|Domain-0"|gawk '{print $1}'`; do
    lvcreate -s -L 1G -n $i-snap snow_vg/$i-disk
done
```
List the snapshots to backup:
```
lvs | grep snap | awk ' { print $1 } '
```
Launch the backup:
```
for i in `lvs | grep snap | awk ' { print $1 } '`; do
    dd if=/dev/snow_vg/$i of=/sNow/backup/201611/$i.vm.img
done
```
Finally remove the LVM snapshots:
```
for i in `lvs | grep snap | awk ' { print $1 } '`; do lvremove snow_vg/$i; done
```
