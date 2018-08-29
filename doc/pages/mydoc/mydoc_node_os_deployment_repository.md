---
title: OS Deployment Repository
tags: [deployment, repository]
last_updated: July 16, 2016
keywords: deployment, repository
summary: ""
sidebar: mydoc_sidebar
permalink: mydoc_node_os_deployment_repository.html
folder: mydoc
---
If you don't have a local repository on your system you will need one to deploy the compute nodes. It is useful if you want to ensure you always have the same configuration on your cluster and all packages replicated in local repositories, since when using public repositories the software versions will change without notice.

The easiest way to have an usable repository for CentOS that will work out of the box is by exporting the CentOS install ISO via NFS:

```
mkdir -p /sNow/OS/CentOS/7.0/DVD1
wget http://buildlogs.centos.org/rolling/7/isos/x86_64/CentOS-7-x86_64-Minimal.iso
mount -o loop CentOS-7-x86_64-Minimal.iso /mnt/
cp -pr /mnt/* /sNow/OS/CentOS/7.0/DVD1/
umount /mnt
rm CentOS-7-x86_64-Minimal.iso
```
If you prefer to set up a real CentOS repository clone, please check "How to create a local repository in your sNow! System". You will then need to update the install repository with the following command to account for your changes:

```
snow set node <node|node range> --install_repo "nfs:<NFS_SERVER_IP>:/sNow/common/CentOS-7-1611-DVD1"
```

{% include tip.html content="In order to accelerate the deployment in large installations, we suggest to to use multiple NFS servers and setup different ```install_repo``` for a subset of nodes. For very large installations, we suggest to consider diskless image provisioning." %}

Consider applying your changes in a new template in order to have a working one.
