---
title: sNow! Installation
tags: [getting_started, troubleshooting]
keywords:
summary: "Installation of sNow!"
sidebar: mydoc_sidebar
permalink: mydoc_install_snow.html
folder: mydoc
---

<div class="alert alert-success" role="alert"><i class="fa fa-download fa-lg"></i> The following check list can help to define all the information required to install an HPC cluster. Consider downloading and filling up the <a href="images/configuration_check_list.pdf">PDF</a> form before to get started.</div>

The sNow! default configuration will setup a completely functional HPC cluster. Additional changes may be required to customise the cluster to suit your needs. Access as root user in the sNow! server and follow one of the two following installation methods:

## Default install (recommended)
```
cd /sNow
git clone http://bitbucket.org/hpcnow/snow-tools.git
cd snow-tools
./install.sh
```
### Custom install
```
git clone http//bitbucket.org/hpcnow/snow-tools.git
cd snow-tools
```
You can customise the installation by exporting environment variables according to your needs. After several installations we have seen a common need for updating the sNow! admin user UID and GID in order to avoid conflicts with the existing users in LDAP. Other than that, the rest of default options are suitable for most cases.
### Define sNow! nodes
By default, sNow! assumes that the current node is the only sNow! management node, which is also a NFS server. If you are installing an additional sNow! management node or you are using an external NFS server, the following environment variables will modify the install process.

If you are interested in changing the hostname to distribute services across more sNow! nodes you need to update the following parameters:
```
export SNOW_MASTER=snow01
```
This must match the hostname of the sNow! master node. If the node where you are performing the installation does not match with the sNow! master node hostname, the install program will assume that the current node is an sNow! slave node.
```
export NFS_SERVER=snow00
```
The name of the host that will be used as an NFS server to serve the /sNow filesystem and the home directory.
### Virtualization technology
At the time this document is written, XEN is the stable technology. LXD and DOCKER requires a complex manual intervention and they are still considered experimental. Note that LXD is only available for Ubuntu.
```
export VIRT_TECH=XEN
```
### Source control and continuous integration support
The following parameters allows you to integrate the key configuration files, deployment scripts and other key codes located in ```/sNow/snow-configspace``` with your source control system. It supports GitHub and BitBucket through OAuth tokens. The default values are empty.
This is key to enable Continuous Integration Support and test changes in a testing environment before merging them into the production environment.
Since the data contained in this folder is extremely sensitive, the GIT repository MUST be private. Since BitBucket allows you to use private repositories for free, we suggest you explore this option. More information about how to setup OAuth integrated applications is available in the GitHub and BitBucket websites.
Example:
```
export PRIVATE_GIT_TOKEN=t54skl3333xxxxxxxxxxyyyy3333333srgrafsiJ
export PRIVATE_GIT_REPO=bitbucket.org/YOUR_ACCOUNT/snow-configspace.git
```
### sNow! paths
The following are the paths used by the sNow! installation and shared across the cluster. They define where the code and binaries are going to be stored. Most of them are NOT customizable yet but they will be in upcoming releases. Keep the following paths as static at this moment unless you know exactly what you are doing.
```
export SNOW_HOME=/home
```
### Admin users
sNow! creates one user by default called snow. If you have already arranged HPCNow! support, an additional user called hpcnow will be created. If the default user/group name, UID or GID are already in use, you can update them by exporting the following variables.

The sNow! user (snow) plays the main admin role.
```
export sNow_USER=snow
export sNow_UID=2000
export sNow_GROUP=snow
export sNow_GID=2000
```
The HPCNow! user (hpcnow) is intended only to enable remote support.
```
export HPCNow_USER=hpcnow
export HPCNow_UID=2001
export HPCNow_GROUP=snow
export HPCNow_GID=2000
```
Please note that to allow the local snow and hpcnow users to log into the system you will to need either:

a. Set a password for the users with passwd
b. Use the created SSH key under ```/home/$USER/.ssh```
### Install sNow!
Finally, run the following command in order to perform the installation.
```
./install.sh
```
If all the stages are successful, you will see a report messages like these:

{% include image.html file="snow_install_logs.png" max-width="300" %}

If any of the stages fail please check the installation log file at ```/tmp/snow-install-*.log``` to troubleshoot.

If you want to review the changes on the config files made by the sNow! installation you can find the ```*-snowbkp``` backup files to see the differences.
```
find /etc -name "*-snowbkp" -print
```
