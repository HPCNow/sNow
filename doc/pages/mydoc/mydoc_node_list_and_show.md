---
title: Compute Node List and Show
keywords: list, compute node
last_updated: March 20, 2016
summary: "This section explains how to list and get key information of the compute nodes already configured in sNow!"
sidebar: mydoc_sidebar
permalink: mydoc_node_list_and_show.html
folder: mydoc
---

## Compute Node List
In order to check the status of the compute nodes and other key information, execute the following command:
```
snow list nodes
```
This list provides detailed information about each compute node, including:
* Name of the compute node
* Status of the hardware
* Status of the OS
* Uptime
* The image associated to the compute node
* The template associated to the compute node
* Date of the last deploy (if using deployment as provisioning mechanism).

Example:
```
snow list nodes atlas-[001-010]
Node                  Cluster          HW status   OS status                                     Image                 Template                        Last Deploy
----                  -------          ---------   ---------                                     -----                 --------                        -----------
atlas-001             atlas            on          up 2 weeks, 1 day, 15 hours, 54 minutes       localboot             centos-7.3-minimal              Wed Mar  7 15:24:12 CET 2018
atlas-002             atlas            on          up 6 days, 14 hours, 46 minutes               localboot             centos-7.3-minimal              Mon Mar  5 10:59:05 CET 2018
atlas-003             atlas            on          up 6 days, 2 hours, 44 minutes                localboot             centos-7.3-minimal              Mon Mar  5 12:52:42 CET 2018
atlas-004             atlas            on          up 2 weeks, 1 day, 15 hours, 54 minutes       localboot             centos-7.3-minimal              Mon Mar  5 12:52:42 CET 2018
atlas-005             atlas            on          up 2 weeks, 1 day, 15 hours, 54 minutes       localboot             centos-7.3-minimal              Mon Mar  5 12:52:42 CET 2018
atlas-006             atlas            on          up 2 weeks, 1 day, 15 hours, 54 minutes       localboot             centos-7.3-minimal              Mon Mar  5 12:52:43 CET 2018
atlas-007             atlas            on          up 2 weeks, 1 day, 15 hours, 54 minutes       localboot             centos-7.3-minimal              Mon Mar  5 12:52:43 CET 2018
atlas-008             atlas            on          up 2 weeks, 1 day, 15 hours, 54 minutes       localboot             centos-7.3-minimal              Mon Mar  5 12:52:43 CET 2018
atlas-009             atlas            on          up 2 weeks, 1 day, 15 hours, 54 minutes       localboot             centos-7.3-minimal              Mon Mar  5 12:52:43 CET 2018
atlas-010             atlas            on          up 2 weeks, 1 day, 15 hours, 54 minutes       localboot             centos-7.3-minimal              Mon Mar  5 12:52:43 CET 2018
```

## Compute Node Show
The following command provides extensive information about the compute nodes, including:
* Cluster associated
* Image used to boot the OS
* Template used to deploy the node(s)
* Install repository
* Console options
* Time of the last deploy01
* Proxy used during the deployment process.
```
snow show nodes <compute_node_name>
```
Example:
```json
snow show node atlas-001
"atlas-001":
{
  "cluster": "atlas",
  "image": "localboot",
  "template": "centos-7.3-minimal",
  "install_repo": "http://vault.centos.org/7.3.1611/os/x86_64/",
  "console_options": "console=tty0 console=ttyS1,57600n8",
  "last_deploy": "Wed Mar 7 15:24:12 CET 2018",
  "install_proxy": "http://10.10.0.8:8080"
}
```
