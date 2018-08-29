---
title: OS Installation - Ubuntu 18.04 LTS
tags: [getting_started, troubleshooting]
keywords:
summary: "OS installation notes for Ubuntu LTS sNow! servers"
sidebar: mydoc_sidebar
permalink: mydoc_install_os_ubuntu.html
folder: mydoc
---
In the following chapters we will discuss how to start from scratch until you have a fully working HPC Cluster.

This starts by installing Ubuntu 18.04 LTS on your sNow! server, typically named snow01. This server will have at least two network ports, one to connect to the internal sNow! network (10.1.0.0 in this document) and one to connect to your site network, which will be for users to interact with the HPC cluster.
## Ubuntu installation
sNow! servers work over Ubuntu. At the time of preparing this documentation it has been fully tested on Ubuntu Bionic Beaver (18.04 LTS).

Download the alternative Ubuntu server installer
Since the sNow! installation may require advanced networking and storage features such as; LVM, RAID, multipath, vlans, bonds, or re-using existing partitions, you will need to use the alternate installer (not the live/default version).

Install Ubuntu as follows:
The partitioning on this installation is based in a system with a single disk OS and sNow!.

Boot from the Ubuntu DVD or USB and choose Install.
1. Select your language, location and keyboard map.
2. Configure your primary network interface to have internet access as you will need it for installing sNow!
3. Choose your hostname (snow01)
4. Choose your domain name and a root password
5. Create a user when prompted (snow user is reserved, so do not use snow as a username)
6. Choose your timezone
7. Choose manual partition, and create a small partition for ```/boot```
```
/boot	ext4	250MB
```
8. Create another partition and lvm	rest of the disk
9. Go to the Logical Volume Manager configuration and write changes to disk.
10. Create a LVM Volume Group and call it: snow_vg
11. Create the following LVM Logical Volumes:
```
root	ext4	20GB		/
tmp   ext4  10GB    /tmp
var   ext4  10GB    /var
sNow	ext4	150GB		/sNow
swap	swap	8GB
```
This is just an example. You can choose other partition layouts that fit your needs but it is mandatory to have the snow_vg volume group and the /sNow filesystem.
12. Configure a network mirror to install new software and updates when needed.
13. Choose the default packages to install. You don't need a GUI for sNow!.
14. Reboot the system when the installation is finished.

## Install pre-required software
Install the following packages, which are needed by the sNow! installation scripts:
```
apt install bridge-utils gawk lvm2 sudo wget git ca-certificates lsb-release git
```
## External shared file system servers (home directory and /sNow folder)
If you are using an external NFS server or a cluster file system to share the home directory and the /sNow folder, then those file systems should be available before installing sNow!
