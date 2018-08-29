---
title: Quick Installation Guide
tags: [getting_started, quick_install]
last_updated: July 3, 2016
keywords: quick install, reference, guide, snow, cli
summary: "Quick and semi-automated installation of sNow! cluster manager allows to provision a new cluster from scratch with a predefined configuration."
sidebar: mydoc_sidebar
permalink: mydoc_install_quick_installation.html
folder: mydoc
---

<div class="alert alert-success" role="alert"><i class="fa fa-download fa-lg"></i> The following check list can help to define all the information required to install an HPC cluster. Consider downloading and filling up the <a href="images/configuration_check_list.pdf">PDF</a> form before to get started.</div>

{% include warning.html content="This section is still under development." %}

1. Boot the sNow! master node with a Debian 9.
2. Press Escape key.
3. Write in the prompt: ```auto url=http://goo.gl/HqKLty```
4. Wait until the system boots the system installed in the local disk.
5. Login as root in order to proceed the installation (Default password is ```HPCN0w!!```).
6. Update the master password (```MASTER_PASSWORD```) and the cluster definition in /sNow/snow-tools/etc/snow.conf
7. Initiate the sNow! configuration with: ```snow init```
8. Initiate the domains deployment with: ```snow deploy domains```
9. Boot the domains with: ```snow boot domains```
10. Add compute nodes with: ```snow add nodes n[01-10]```


<!--
6. The system will request to update the password.
7. The system will request a valid email account and verification code.
-->
