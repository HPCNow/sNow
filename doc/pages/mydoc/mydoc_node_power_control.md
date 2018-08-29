---
title: Compute Node Power Control
keywords: power control, Compute Node
last_updated: March 20, 2016
summary: "This section explains how to boot, shutdown and reboot sNow! Compute Nodes"
sidebar: mydoc_sidebar
permalink: mydoc_node_power_control.html
folder: mydoc
---

## Boot from local disk (localboot)
In order to boot the compute nodes from the OS installed in the local disk, run the following command:
```
snow boot <compute_node(s)> localboot
```
This assumes that deployment is used as provisioning mechanism and the nodes instructed to boot are already deployed.
Unless the compute nodes configuration have been modified the provisioning based on deployment sets the default boot image to ***localboot***, which enables the compute nodes to boot from the local disk.
## Boot from Diskless Image
In order to boot the compute nodes from a specific OS image, run the following command:
```
snow boot <compute_node(s)> <image_name>
```
This assumes that the compute nodes will be able to boot via PXE by using a diskless image.
It is recommended to setup the default OS image. You can setup that globally in ```snow.conf``` by setting the image name as the value of ```DEFAULT_BOOT```. Otherwise, you have setup the default boot per node basis, by using the command ```snow set node --default_boot <image_name>``` (more information available in [Compute Node Setup](mydoc_node_set.html) section).
## Reboot
The following command allows rebooting a specific compute node:
```
snow reboot <compute_node(s)>
```
## Reset
The following command forces rebooting a specific compute node:
```
snow reset <compute_node(s)>
```
## Shutdown
The following command allows shutting down a specific compute node:
```
snow shutdown <compute_node(s)>
```
## Destroy
The following command forces to stop a specific compute node simulating a power button press:
```
snow destroy <compute_node(s)>
```
## Power Off
The following command initiates a soft-shutdown of the OS via ACPI for compute node:
```
snow poweroff <compute_node(s)>
```
{% include callout.html content="Differences between shutdown, destroy and poweroff: <br>**shutdown** requires access to the OS in order to be able to trigger 'systemctl poweroff' command. <br>**destroy** forces to stop specific node simulating a power button press. This is performed at the IPMI level in those situations where the system is up but is not responsive (i.e. a boot failure).<br>**poweroff** initiates a soft-shutdown of the OS via ACPI. This is useful when for some reason you don't have access through SSH but you have access from console (i.e. the system booted without network configuration)." type="success" %}
