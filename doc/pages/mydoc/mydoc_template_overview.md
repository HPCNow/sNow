---
title: Deployment Template Overview
tags: [troubleshooting]
keywords: deployment, templates, compute nodes
last_updated: July 3, 2016
summary: "This section provides an overview of OS deployment templates for the compute nodes."
sidebar: mydoc_sidebar
permalink: mydoc_template_overview.html
folder: mydoc
---
sNow! supports multiple Linux distributions for the deployment for compute nodes. It currently provides a template to deploy CentOS (+ RedHat based distributions), Debian (+ Debian based distributions) and OpenSuSE Leap (+ SuSE based distributions) and the development roadmap includes providing out of the box deployment compatibility with the most popular Linux distributions. If you need a different Linux flavour, please contact HPCNow! or a sysadmin specialist in order tailor the solution to your needs.

{% include note.html content="You need to configure your compute nodes to boot from PXE from the first (usually) network interface." %}

You can list all of the available templates with the following command:
```
snow list templates
```
This command provides relevant information about each available template in your sNow! installation, including the path where the template files are located. In that folder you will find:
* The main postconfig script which is distribution agnostic (postconfig.sh)
* The list of required kernels to boot the system from PXE. These are usually downloaded during the sNow! server installation and defined in pxe_kernels.conf. This file only needs to be updated if you are using custom kernels and you also want to setup continuous integration or a disaster recovery environment.
* The templates are defined by a subset of files located in a folder with the same name of the template.

The schema of the template is defined in the following example based on the default CentOS 7 template, which is located in the following folder:
```
/sNow/snow-configspace/boot/templates/centos-7.3-default
```
* ```initrd.img``` is a scheme for loading a temporary root file system into memory, which may be used as part of the Linux startup process.
* ```vmlinuz``` is a compressed Linux kernel, and it is capable of loading the operating system into memory via PXE so that the computer becomes usable and applications can be run.
* ```config``` contains environment variables used during installation. By default, it contains the sNow! and HPCNow! user UID and GID.
* ```repos``` contains a list of package repositories and the url to the keys (if required). It supports unix path, https, http and ftp protocols.
* ```packages``` a complete list of packages to be installed during the deployment of the node
* ```??-hook-name.sh``` This folder also allows you to include some scripts to be executed at the end of deployment. This is a really easy way to customize your deployment without too much hassle. The name schema for those scripts is a number from 01 to 99, a string, followed by .sh extension. The scripts must have rights to be executed by root.
* ```first_boot/??-hook-name.sh``` This folder allows you to include some scripts that may need to be executed once the deployed node boots for first time. The name schema is exactly the same as used in the regular hooks described above.
* ```centos-7.3-default.cfg``` is the Kickstart file which contains very basic deployment information, such as partition layout, MBR setup, etc. You might want to change some defaults here, like the partition layout.
* ```centos-7.3-default.pxe``` is the PXE configuration file used to boot the OS in order to proceed with automatic deployment.

{% include important.html content="The name of this file MUST match the name of the template, which is also the name of the folder which contains these files. The extension must be ```.pxe```." %}

If you want to be able to see the console during the deployment of a node you must edit the .pxe file in order to enable the console redirection. In the BIOS of your compute node you will need to enable Console Redirection, choose a COM port (usually COM1 or COM2), and choose serial communication parameters. The default values are defined in snow.conf with the following parameter:
```
DEFAULT_CONSOLE_OPTIONS="console=tty0 console=ttyS0,115200n8"
```
Examples:
* For COM1, 57600 baud, 8 bit data, no parity: ```console=ttyS0,57600n8```
* For COM2, 115200 baud, 8 bit data, no parity: ```console=ttyS1,115200n8```

This configuration is highly dependent on your BIOS manufacturer. If you are unsure check with your hardware provider to determine the correct redirection values.

If you want to change the console redirection settings for a specific node in the cluster you have to interact with the node JSON file. To do this:

```json
root@snow01:~# snow show nodes node019
{
  "cluster": "mycluster",
  "image": "localboot",
  "template": "centos-7.3-minimal",
  "install_repo": "nfs:10.0.0.1:/sNow/common/CentOS-7-1611-DVD1",
  "console_options": "console=tty0 console=ttyS0,115200n8",
  "last_deploy": "Thu May 11 20:43:31 CEST 2017"
}
root@snow01~# snow set node bbgn019 --console_options "console=tty0 console=ttyS1,57600n8"
[W] Do you want to apply the changes in the node(s) bbgn019? [y/N] (20 seconds)  
y
root@snow01:~# snow show nodes node019
{
  "cluster": "mycluster",
  "image": "localboot",
  "template": "centos-7.3-minimal",
  "install_repo": "nfs:10.0.0.1:/sNow/common/CentOS-7-1611-DVD1",
  "console_options": "console=tty0 console=ttyS1,57600n8",
  "last_deploy": "Thu May 11 20:43:31 CEST 2017"
}
```
