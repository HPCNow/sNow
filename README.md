# README

sNow! Tools includes the CLI, templates and profiles for interacting with sNow! Cluster Manager.

## Overview

sNow! is an OpenSource HPC suite which provides all the required elements to deploy, manage and customize a compute solution. With the sNow! default configuration you will able to setup a completely functional HPC cluster from scratch in very short time.

The predefined configuration contains advanced features which significantly reduce additional complexities for the end user. In addition to that, sNow! allows to integrate simple hook scripts to customize your system in order to meet your needs.

We believe that HPC facilities will take advantage of this work and they will be able to deliver all this material to their end users after applying minor changes in the configuration and also in the documentation.

## Quick Install Notes
1. This starts by installing Debian on your sNow! server, typically named snow01. This server will have at least two network ports, one to connect to the internal sNow network (192.168.7.0 in this document) and one to connect to your house network, which will be used for the users to be able to interact with the computing cluster.

2. Extend the repos with contrib and non-free 

3. Install pre-required software

```
apt-get install bridge-utils gawk lvm2 sudo wget git
```

4. Execute the following commands to start the sNow! installation

```
git clone https://bitbucket.org/hpcnow/snow-tools.git 1.1.1
cd snow-tools
./install.sh
```

## sNow! Configuration

1. Setup network bridges
Each sNow! server will require at least two and up to five network bridges. If you want to reduce complexity in the setup, consider to select a server with four physical networks or attach a multi-nic network adapter. Otherwise, if you prefer to reduce number of cables, physical ports and also the number of switches you can use tagged VLANs as explained in section 9 (Advanced Network Setup).

The following diagrams represent common scenarios. Please, review carefully what scenario do you want to develop.

Figure 1: These diagrams represent three simple scenarios attending to the OS network requirements. Since the IPMI interface is completely independant from OS point of view, the IPMI cables are not represented in these diagrams, but those cables are connected from IPMI interface to the management switch. 

Edit /etc/network/interfaces and configure the network bridges using the most suitable template. Please review carefully the file and adapt it to your real network environment.

a. Scenario A (most popular)
The snow system and the domains (VMs or containers) that need to be accessed by the users (login node, monitor node) have an IP of your LAN and are directly accessible for the users in the LAN.

The nodes have access to the internet via NAT using the snow01 server as default gateway and the proxy01 VM as proxy server.

This is the easiest and most common solution. You are the ultimate responsible of taking care of the security measures which prevent undesired access to your LAN.
LINK

b. Scenario B
There is an external router that can implement NAT rules to the DMZ network. In this case the sNow! server(s) will expose all the public services in the DMZ network bridge (xdmz0) without any filter. This configuration is recommended because it allows to scale to several sNow! servers and achieve this way resilience, flexibility and better performance.
LINK

c. Scenario C
There is only one sNow! server and it has a public IP address. In this case the sNow! needs to operate as router and firewall in order to limit the access to critical services exposed in the DMZ.
LINK

## Customize your cluster before initializing
The sNow! configuration file (snow.conf) is the main configuration file of sNow!. It provides a complete list of parameters which will be used to setup the HPC cluster.

A template of this file is available in /sNow/snow-tools/etc/snow.conf-example. In order to get started, copy the template file to /sNow/snow-tools/etc/snow.conf and then edit snow.conf to suit your particular needs.

```
cp -p /sNow/snow-tools/etc/snow.conf-example /sNow/snow-tools/etc/snow.conf
```

### Selecting domains
Note: In this documentation we are referring the independent systems running different sNow services as "domains" or "virtual machines" or "containers". 

Each domain has one or multiple roles. Each role defines a service or a subset of related services. The roles are scripts which automatize the process of deploying a new domain and also reconfigure them based on the parameters available in the main sNow! configuration file (snow.conf). The following command line, provides a short description for each available role.

```
snow list roles
```

The active-domains.conf configuration file contains a list of domains that suits most common needs. Add or delete lines as required by your installation needs.

```
cp -p /sNow/snow-tools/etc/active-domains.conf-example /sNow/snow-tools/etc/active-domains.conf
```

The first column of the active-domains.conf file contains the hostname of the domain, the second column contains the role or list or roles associated with the domain. Each domain can have one or more roles. In case of multiple roles use a comma separated list (with no spaces).

If a domain has multiple roles, each role script will be executed in the same order defined in the domains.conf. This file will be automatically generated with the "snow init" command, as described in the section 6.4. The current available roles are located in /sNow/snow-tools/etc/roles.d. This document provides information of key roles but all the available roles.

### Iniciate sNow! system
The sNow! domains configuration file (domains.conf) provides a table of parameters for each sNow! domain, including the associated roles which define the services provided by each domain (see active-domains.conf) and also the network parameters.
This file is generated by executing "snow init" command, but it can be modified to accommodate site specific requirements.

```
snow init
```

### Download the sNow! domain image template
sNow! relies on pre-built domain images which are used as a template in the roles deployment. This allows to accelerate the domains deployment. It’s a good practice to update this image before to create any new service in order to fix potential bugs.

The following command looks for a new update in the public repository, and in the case of a new update available, it will download the new image. The size of the image is around 250MB, so expect some delay here.

```
snow update template
```

### Domains Deployment
Some domains have internal dependencies with others. At the time this guide is written, sNow! is not able to resolve these dependencies, but it will in a future release. The following commands are sorted in such a way that can solve the dependencies.

Each domain usually takes between one and two minutes to be deployed and booted, although this depends on your system's performance. The aim is to be able to run the first job in your cluster in less than one hour.

If you want to see what is happening during the deploy process, you can open a new shell and review the output of the log file at real time, using the following command line (this is also valid during any interaction with the snow command):

```
tail -f /sNow/log/snow.log
```

In order to deploy the default domains, run the following commands:

```
snow deploy deploy01
snow deploy ldap01
snow deploy syslog01
snow deploy proxy01
snow deploy slurmdb01
snow deploy slurm01
snow deploy monitor01
snow deploy login01
```

Once you have deployed all the domains, you can boot them by running the following commands:

```
snow boot domains
```

In order to ensure that all the domains are up and running, execute the following command:

```
snow list domains
```

### Compute Nodes deployment
At this point you should be able to deploy the compute nodes using any of the templates available in the system. You can list the available templates with the following command:

```
snow list templates
```

In order to deploy a node or a list of nodes, execute the following command:

```
snow deploy node[001-010] template_name
```

It is a common practice to assign static IP addresses to compute nodes. Please consider to user the fishermac tool to collect the macaddresses and associate them with the proper IP addresses. More information in the Official sNow! Administration Guide.

