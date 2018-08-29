---
title: Image Overview
tags: [image, nfsroot, stateless, diskless]
keywords: rouge, pygments, prettify, color coding,
last_updated: July 3, 2016
summary: "In order to ensure consistency across the cluster you can use the sNow! native image management system. This way, all the compute nodes can share the same consistent OS and configuration.
"
sidebar: mydoc_sidebar
permalink: mydoc_image_overview.html
folder: mydoc
---
Images are gathered from already deployed nodes which means that at least one of the compute nodes must have local disks to install the OS (usually the golden node). Once the image is created, the nodes no longer need local disk for the OS. They can use these drives for temporary IO (local scratch) instead.
## Single System Image based on nfsroot (SSI)
The current release supports diskless images based on read-only nfsroot and only supports CentOS and Red Had based Linux distributions. In the future releases it will be also be available for SuSE Linux based distributions.
Nodes can boot from PXE and load the OS from the NFS server. While the root file system is read only, the system allows applying some changes in memory by using tmpfs. This is suitable for updating a few configuration files, PID files and some logs. Major changes should be applied directly in the image, otherwise the memory footprint may be high.
## Stateless
The current release supports diskless images based on read-only SquashFS and OverlayFS to load the root file system in-memory. Compared to other stateless solutions (ramdisks, tmpfs, etc.), SquashFS significantly reduces the memory footprint because the root file system is compressed.
Nodes can boot from PXE and load the OS from the NFS server or TFTP server (deploy role). While the main root file system is read only, the system allows applying some changes in memory by using OverlayFS on top of tmpfs. This is suitable for updating a few configuration files, PID files and some logs. Major changes should be applied directly in the image, otherwise the memory footprint may be even higher.
