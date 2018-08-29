---
title: Configuration example for Scenario A
tags: [publishing]
keywords: network
last_updated: July 3, 2016
summary: "scenario A."
sidebar: mydoc_sidebar
permalink: mydoc_install_scenario_a.html
folder: mydoc
---
The following example shows how to setup the public bridge and the sNow! (private) network bridge.

We will define the following bridges:
* xsnow0 as the private bridge for node deployment and administration. It uses the eth0 interface.
* xpub0  as the public bridge for the house network. It uses the eth1 interface.

Additionally we will define:
An alias IP on the xsnow0 bridge to access the IPMI interfaces on the nodes (mandatory if they are not in the same network)

Optionally we will define:
An IP on the ib0 Infiniband interface or in the high speed network interface of your choice.

In order to enable the required network bridges, follow the next four simple steps:

1. Download the example configuration file from our website, update the IP addresses and remove the configuration blocks that you do not need. Please, carefully review the file and adapt it to your real network environment.
* Debian: Edit /etc/network/interfaces by following this [example file](examples/network_interfaces_scenario_a.txt)
* Ubuntu: Edit /etc/netplan/01-netcfg.yaml by following this [example file](examples/netplan_scenario_a.txt)
2. After the network configuration file is edited, reboot the system and check your configuration has been applied with the following command:
```
ip addr show
```
3. The expected output should be similar to the following text:
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master xpub0 state UP group default qlen 1000
    link/ether 08:00:27:3c:04:cb brd ff:ff:ff:ff:ff:ff
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master xsnow0 state UP group default qlen 1000
    link/ether 08:00:27:30:38:ac brd ff:ff:ff:ff:ff:ff
4: xpub0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 08:00:27:3c:04:cb brd ff:ff:ff:ff:ff:ff
    inet YOUR_LAN_IP_ADDRESS/24 brd YOUR_LAN_BROADCAST scope global xpub0
       valid_lft forever preferred_lft forever
5: xsnow0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 08:00:27:30:38:ac brd ff:ff:ff:ff:ff:ff
    inet 10.1.0.1/16 brd 10.1.1.255 scope global xsnow0
       valid_lft forever preferred_lft forever
```
4. You can check the bridges and their associated network interfaces with the following command:
```
brctl show
bridge name    bridge id   	    STP enabled    interfaces
xpub0   	    8000.001e67d60e4f    no   	         eth1
xsnow0   	    8000.001e67d60e4e    no   	         eth0
```
