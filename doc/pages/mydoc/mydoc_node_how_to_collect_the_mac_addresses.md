---
title: How to collect the MAC addresses
tags: [mac address]
keywords: mac, mac address
last_updated: July 16, 2016
datatable: true
summary: "Collecting the MAC addresses in a cluster is simple but can be time consuming. This section explains some tricks to avoid spending too much time doing this."
sidebar: mydoc_sidebar
permalink: mydoc_node_how_to_collect_the_mac_addresses.html
folder: mydoc
---
Collecting the MAC addresses in a cluster is simple but can be time consuming. This section explains some tricks to avoid spending too much time doing this.

The deployment node will track all the DHCP requests each time a node is booted. Booting the nodes in the desired order will fill the dhcp.leases file in the this order. Using the dhcp.leases file you will be able to get all the MAC addresses of your compute nodes which can then be used to assign static IP addresses based on the MAC addresses in the /etc/ethers file. Consider proceeding as follows:
1. Boot the first node and measure the time it takes until it makes its PXE request.
2. Boot the other nodes by giving enough time to avoid a mistake in the order of receiving the DHCP request. Usually 15 to 30 seconds is enough.
3. Once you have all the nodes up and running, you can take advantage of the following helper script to generate the static IP assignment in the right order.
```
fishermac /var/lib/misc/dnsmasq.leases > /etc/ethers
```
4. Review the content of the /etc/ethers and correct the order of the generated list if required. You can also manually add addresses if needed.
5. Restart the dnsmasq daemon in order to apply the new changes.
6. Transfer the updated version of /etc/ethers to ${SNOW_SRV}/deploy_files/etc
```
scp -p deploy01:/etc/ethers ${SNOW_SRV}/deploy_files/etc/
```
