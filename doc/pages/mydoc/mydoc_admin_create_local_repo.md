---
title: How to create a local repository in your sNow! system
tags: [local_repo]
keywords: local repository
last_updated: July 3, 2016
summary: "This section explains how to setup a local repository in your sNow! system in order to accelerare the deployment of the compute nodes and domains."
sidebar: mydoc_sidebar
permalink: mydoc_admin_create_local_repo.html
folder: mydoc
---

To be able to install from a local Centos DVD image, follow these instructions to download and copy the installation files to a suitable location:
```
mkdir /sNow/common/CentOS-7-1708
cd /tmp
wget wget http://mirror.tedra.es/CentOS/7/isos/x86_64/CentOS-7-x86_64-DVD-1708.iso
mount -o loop /tmp/CentOS-7-x86_64-DVD-1708.iso /mnt
cp -pr /mnt/* /sNow/common/CentOS-7-1708
umount /mnt
rm /tmp/CentOS-7-x86_64-DVD-1611.iso
```

Then modify the install_repo in the json node file by:
```
snow set node bbgn[001-018] --install_repo nfs:<NFS_SERVER_IP>:/sNow/common/CentOS-7-1708
```

In many cases you will also need additional repositories, like EPEL, or a site specific RPM repo. In order to accommodate these requirements you will need native CentOS tools.

Install the yum-utils and createrepo packages
```
yum install yum-utils createrepo -y
```
Install the required repos to syncronize with your local shared file system:
```
rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-<VERSION>.noarch.rpm
```
Use contrib scripts available in /sNow/snow-tools/contrib/repo_sync
Setup the LOCALREPODIR variable inside the script and run it to update the CentOS repo.

* sync-centos-official.sh (syncronize official CentOS repo)
* sync-centos-epel.sh (syncronize EPEL CentOS repo)
* sync-centos-hpcnow.sh (syncronize HPCNOw! CentOS repo)
* sync-centos-local.sh (create your custom repo)
