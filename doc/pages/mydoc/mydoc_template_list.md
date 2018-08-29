---
title: Template List
tags: [template deployment cloning]
keywords: template, deployment, cloning
last_updated: July 3, 2016
summary: "This section explains how to get a list of the templates installed in your sNow! cluster."
sidebar: mydoc_sidebar
permalink: mydoc_template_list.html
folder: mydoc
---
The following command provides relevant information about each available template in your sNow! installation:
```
snow list templates
```
Including:
* The name of the template.
* Short description of the template.
* The path where the template files are located.
* List of hooks which allows you to include some scripts to be executed at the end of deployment.

Example:
```
Template Name                     Description
-------------                     -----------
opensuse-leap-42.2-x64-default    Default template based on OpenSUSE Leap 42.2
                                  path: /sNow/snow-configspace/boot/templates/opensuse-leap-42.2-x64-default
debian-9-x64-minimal              Minimal template based on Debian 9 (Stretch)
                                  path: /sNow/snow-configspace/boot/templates/debian-9-x64-minimal
centos-7.0-x64-default            Default template based on CentOS 7.0
                                  path: /sNow/snow-configspace/boot/templates/centos-7.0-x64-default
centos-7.4-x64-default            Default template based on CentOS 7.4 1708
                                  path: /sNow/snow-configspace/boot/templates/centos-7.4-x64-default
centos-7.3-x64-minimal            Minimal template based on CentOS 7.3 1611
                                  path: /sNow/snow-configspace/boot/templates/centos-7.3-x64-minimal
                                  hooks:
                                  - 10-Configure_lscratch_IPM.sh
                                  - 20-Tune-fstab.sh
                                  - 30-IPoIB-setup.sh
                                  - 40-BeeOND-setup.sh
                                  - 45-Create_links_and_mountpoints.sh
                                  - 50-NIS-client-setup.sh
                                  - 55-Torque-install.sh
                                  - 60-limits-setup.sh
                                  - 65-crontab.sh
                                  - 70-Tune-sshd.sh
                                  - 80-Tune-docker.sh
                                  - 90-MDRaid-alert-setup.sh
                                  - 95-Tune-GRUB.sh
centos-7.4-x64-minimal            Minimal template based on CentOS 7.4 1708
                                  path: /sNow/snow-configspace/boot/templates/centos-7.4-x64-minimal
centos-7.3-x64-default            Default template based on CentOS 7.3 1611
                                  path: /sNow/snow-configspace/boot/templates/centos-7.3-x64-default
debian-8-x64-minimal              Minimal template based on Debian 8 (Jessie)
                                  path: /sNow/snow-configspace/boot/templates/debian-8-x64-minimal
```
