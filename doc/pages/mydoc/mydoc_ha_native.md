---
title: Native High Availability
sidebar: mydoc_sidebar
tags: [ha, high_availability]
permalink: mydoc_ha_native.html
folder: mydoc
---

The most critical services already have native HA support, which doesn’t rely on third party software packages. This is the case for slurmctld, LDAP, NTP, Squid or DNS. Unfortunately, some other services do not have those features implemented. In order to achieve resilience in case of a hardware failure in one of the sNow! servers, the backup or replicated domains should be allocated in a different sNow! server. The following list includes the domains in which sNow! is capable of automatically enabling HA support:

* Slurmctld: sNow! provides two roles for slurmctld, the slurmctld-master and slurmctld-slave
* LDAP: sNow! provides two roles, ldap-master, ldap-mirror
* proxy: each domain will automatically offer HA for NTP, Squid and DNS services. 
* deploy: each deployment node allocated in a different sNow! server will accelerate the deployment and the booting of the cluster. Those domains also provide HA for DNS, DHCP and TFTP.

The installation of the two or more sNow! servers is quite simple as long as the /sNow folder is shared across the nodes, including the sNow! servers. We suggest using NFS servers or a cluster file system to share this folder.

