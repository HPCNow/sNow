---
title: Configuration example for Scenario B
tags:
  - network
keywords: "network"
last_updated: "November 30, 2016"
summary: "Configuration example for Scenario B."
sidebar: mydoc_sidebar
permalink: mydoc_install_scenario_b.html
folder: mydoc
---

The following example shows how to setup the DMZ bridge where the domains will be attached and the sNow! network bridge. On top of this configuration, there are some firewall rules that may be required in order to expose some of the services of the DMZ.

* xsnow0 as the private bridge for node deployment and administration. It uses the eth0 interface.
* xmgmt0 as the management bridge for accessing consoles and the IPMI interfaces on the nodes. It uses the eth1 interface.
* xdmz0  as the DMZ bridge for the house network. It uses the eth2 interface.
* xllf0  as the Low Latency Fabric network bridge used by cluster filesystem and/or MPI. In this example, it uses the eth3 interface which is the virtual interface enabled by using Mellanox eIPoIB. More information in this regard is available in section 9 (Advanced Network Setup).

In order to enable the required network bridges, follow the next four simple steps:

1. Download the example configuration file from our website, update the IP addresses and remove the configuration blocks that you do not need. Please, carefully review the file and adapt it to your real network environment.
* Debian: Edit /etc/network/interfaces by following this [example file](examples/network_interfaces_scenario_b.txt)
* Ubuntu: Edit /etc/netplan/01-netcfg.yaml by following this [example file](examples/netplan_scenario_b.txt)
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
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master xdmz0 state UP group default qlen 1000
    link/ether 08:00:27:3c:04:cb brd ff:ff:ff:ff:ff:ff
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master xsnow0 state UP group default qlen 1000
    link/ether 08:00:27:30:38:ac brd ff:ff:ff:ff:ff:ff
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master xmgmt0 state UP group default qlen 1000
    link/ether 08:00:27:30:38:ad brd ff:ff:ff:ff:ff:ff
5: xdmz0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 08:00:27:3c:04:cb brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.1/24 brd 172.16.0.255 scope global xdmz0
        valid_lft forever preferred_lft forever
6: xmgmt0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 08:00:27:30:38:ad brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.1/16 brd 10.0.1.255 scope global xmgmt0
       valid_lft forever preferred_lft forever
7: xsnow0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 08:00:27:30:38:ac brd ff:ff:ff:ff:ff:ff
    inet 10.1.0.1/16 brd 10.1.1.255 scope global xsnow0
       valid_lft forever preferred_lft forever
```
4. After that, you need to setup the firewall. This process will require manual setup in your external firewall. The dmz_portmap.conf file contains all the NAT rules associated with each role.
