---
title: How to setup a sNow! bridge on top of a network bonding
tags: [network, bonding]
last_updated: November 30, 2015
keywords: bridge, bridges, network, networking, bonding
summary: "This section explains how to setup network bridges with bonding in order to achieve high availability and better performance."
permalink: mydoc_install_network_bonding.html
sidebar: mydoc_sidebar
folder: mydoc
---

Network bonding applies to various methods of aggregating multiple network connections in parallel in order to increase throughput and to provide redundancy in case one of the links should fail.

A Link Aggregation Group (LAG) combines a number of physical ports together to make a single high-bandwidth data path, so as to implement the traffic load sharing among the member ports in the group and to enhance the connection reliability.

Redundancy is the key factor in mission critical environments where downtime is not an option.

Using network bonding may require some switch configuration. There are seven modes of network bonding in Linux. For more information visit the following [url](https://help.ubuntu.com/community/UbuntuBonding).

This section explains how to use *Adaptive transmit load balancing* (balance-tlb) and define the network bridges over those virtual interfaces. The balance-tlb Linux bonding driver mode, does not require any special network-switch support.

## Edit your interfaces configuration

```
sudo vi /etc/network/interfaces
```

## Define slaves to the bonding interface
In this example, the eth0 and eth1 are combined as slaves to the bonding interface bond0, and eth2 and eth3 are combined as slaves to the bonding interface bond1.
```
auto eth0
allow-hotplug eth0
	iface eth0 inet manual
	bond-master bond0

auto eth1
allow-hotplug eth1
 	iface eth1 inet manual
 	bond-master bond0

auto eth2
allow-hotplug eth2
 	iface eth2 inet manual
 	bond-master bond1

auto eth3
allow-hotplug eth3
     iface eth3 inet manual
 	bond-master bond1

auto bond0
allow-hotplug bond0
     iface bond0 inet manual
    	bond-mode balance-tlb
    	bond-miimon 100
    	bond-downdelay 200
    	bond-updelay 200
    	bond-slaves eth0 eth1

auto bond1
allow-hotplug bond1
     iface bond1 inet manual
    	bond-mode balance-tlb
    	bond-miimon 100
    	bond-downdelay 200
    	bond-updelay 200
    	bond-slaves eth2 eth3
```
## Define Network Bridges Over Bonding Interface
The network bridges are defined in the same way described in the previous sections. Each bridge only requires to define the interface (in this case bond0 and bond1) as the value of the parameter ```bridge_ports```:
```
auto xsnow0
iface xsnow0 inet static
        bridge_ports bond1
        address 192.168.7.1
        netmask 255.255.255.0
        network 192.168.7.0
        broadcast 192.168.7.255

auto xpub0
iface xpub0 inet static
        bridge_ports bond0
        address 150.241.212.36
        gateway 150.241.212.1
        netmask 255.255.255.0
        broadcast 150.241.212.255
        network 150.241.212.0
        dns-nameservers 150.241.212.11 150.241.212.26
```

<!--
## Define VLANs Over a Bonding Interface
You can create a VLAN over a bonding interface an then create a bridge. 

If you create VLAN interfaces only to put them into a bridge, there is no need to define the VLAN interfaces manually. Just config the bridge, and the VLAN interface will be created automatically when creating the bridge, e.g:


```
auto vlan10
iface vlan10 inet static
        vlan-raw-device bond0
```
-->
