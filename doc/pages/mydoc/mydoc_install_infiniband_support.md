---
title: Enable Infiniband support with eIPoIB
last_updated: May 17, 2016
summary: "This section explains how to enable Infiniband support with eIPoIB in the sNow! domains."
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_install_infiniband_support.html
folder: mydoc
---
Please review the Mellanox OFED user guide for more complete and up to date and documentation: [Mellanox OFED Release Notes 3.3.1.0.4](http://www.mellanox.com/related-docs/prod_software/Mellanox_OFED_Linux_Release_Notes_3_3-1_0_4_0.pdf)

## Enabling the eIPoIB Driver
Once the Mellanox OFED driver installation is completed, perform the following:
1. Open the /etc/infiniband/openib.conf file and include:
```E_IPOIB_LOAD=yes```
2. Restart the InfiniBand drivers.
```systemctld restart openibd```
3. Configure the Ethernet Tunneling Over IPoIB Driver. When eth_ipoib is loaded, a number of eIPoIB interfaces are created, with the following default naming scheme: ethX, where X represents the ETH port available on the system.
4. To check which eIPoIB interfaces were created:
```cat /sys/class/net/eth_ipoib_interfaces```
For example, on a system with dual port HCA, the following two interfaces might be created; eth4 and eth5.
5. Create the eIPoIB bridge. These interfaces can be used to configure the network for the guest. For example, if the guest has a VIF that is connected to the Virtual Bridge br0, then enslave the eIPoIB interface to xllf0 by running:
```brctl addif xllf0 eth4```
6. The IPoIB daemon (ipoibd) detects the new virtual interface that is attached to the same bridge as the eIPoIB interface and creates a new IPoIB instance for it in order to send/receive data. As a result, a number of IPoIB interfaces (ibX.Y) are shown as being created/destroyed, and are being enslaved to the corresponding ethX interface to serve any active VIF in the system according to the set configuration, This process is done automatically by the ipoibd service.
To see the list of IPoIB interfaces enslaved under eth_ipoib interface.
```cat /sys/class/net/ethX/eth/vifs```
