---
title: Setup Network Bridges
keywords: network bridge
last_updated: March 20, 2016
summary: "Setup network bridges."
sidebar: mydoc_sidebar
permalink: mydoc_install_setup_network_bridges.html
folder: mydoc
---

Each sNow! server will require at least two and up to five network bridges. If you want to reduce complexity in the setup, consider selecting a server with four physical networks or attach a multi-nic network adapter. Otherwise, if you prefer to reduce the number of cables, physical ports and the number of switches you can use tagged VLANs as explained in section 9 (Advanced Network Setup).

The following diagrams represent common scenarios. Please review carefully which scenario you want to develop.

{% include image.html file="scenario_a.jpg" url="./images/scenario_a.jpg" alt="scenario A" caption="Scenario A" %}
{% include image.html file="scenario_b.jpg" url="./images/scenario_b.jpg" alt="scenario B" caption="Scenario B" %}
{% include image.html file="scenario_c.jpg" url="./images/scenario_c.jpg" alt="scenario C" caption="Scenario C" %}

{% include note.html content="Figure 2: These diagrams represent three simple scenarios attending to the OS network requirements. Since the IPMI interface is completely independant from an OS point of view, the IPMI cables are not represented in these diagrams, but those cables are connected from the IPMI interface to the management switch." %}


## Scenario A (most popular)
The snow system and the domains (VMs or containers) that need to be accessed by the users (login node, monitor node) have an IP of your LAN and are directly accessible for the users in the LAN.

The nodes have access to the internet via NAT using the snow01 server as default gateway and the proxy01 VM as proxy server.

This is the easiest and most common solution. You are ultimately responsible for taking care of security measures which prevent undesired access to your LAN.

## Scenario B
There is an external router that can implement NAT rules to the DMZ network. In this case the sNow! server(s) will expose all the public services in the DMZ network bridge (xdmz0) without any filter. This configuration is recommended because it allows scaling to several sNow! servers and thus achieving resilience, flexibility and better performance.

## Scenario C
There is only one sNow! server and it has a public IP address. In this case, the sNow! server needs to act as router and firewall in order to limit the access to critical services exposed in the DMZ.

Edit /etc/network/interfaces and configure the network bridges as follows. You might need another interface for accessing the IPMI interfaces on the compute nodes in order to control them.

{% include tip.html content="If you are not familiar with network bridges, please read: https://wiki.xenproject.org/wiki/Xen_Networking" %}
