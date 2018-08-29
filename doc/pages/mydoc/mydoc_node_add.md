---
title: Add Compute Nodes
keywords: deploy, compute node
last_updated: July 3, 2016
tags: [deploy]
summary: "This section explains how to add a new node definition in the sNow! database"
sidebar: mydoc_sidebar
permalink: mydoc_node_add.html
folder: mydoc
---
The compute nodes are initially defined in snow.conf by the ```CLUSTERS``` variable. Updating this value in snow.conf will not modify, add or remove nodes in the sNow! database. The following command allows you to add and define new compute nodes.
```
snow add node <compute_node> [--option value]
```
The available options are:
* ```--cluster```: defines the cluster associated to that particular node(s)
* ```--image```: defines the image to boot the system from
* ```--template```: defines the template used for provisioning the compute node
* ```--install_repo```: defines the installation proxy. Used to load-balance the HTTP/FTP access to the RPMs/DEB packages.
* ```--console_options```: defines the console options
