---
title: List Roles
tags: [domains]
keywords: domains, roles, vms, containers
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_role_list.html
folder: mydoc
---

The following command line, provides a short description for each role available in ```/sNow/snow-tools/etc/roles.d```.

* For more information about sNow! domain roles, visit the [Available Roles](mydoc_role_available.html) section.
* For more information about how to develop a custom role, visit the [Custom Roles](mydoc_role_custom.html) section.

```
snow list roles
```
Example output:
```
snow list roles
Role Name                     Description
-------------                 -----------
beegfs                        This role installs BeeGFS server
builder                       Minimal OS to compile code and generate debian packages
cfengine                      Installs CFenfine upon the new guest system
cfs                           Allows to setup NFS client and cluster file system clients (experimental)
deploy                        Installs the required to deploy OS and boot OS via PXE and TFTP. It also provides DHCP and DNS.
docker                        Installs Docker Community Edition and Docker compose
gateone                       Installs Gate One, a web based terminal emulator and SSH client
gdm                           Installs GDM with VNC support.
icinga                        Installs standard HPC alert tool: Icinga.
ldap-master                   Installs LDAP master server.
login                         Installs login node with workload manager clients and creates a new SSH instance allocated in 22022/TCP dedicated to end users.
minimal                       Installs a minimal OS.
monitor                       Installs standard HPC monitoring tools : Ganglia and Icinga.
openvpn_as                    Installs OpenVPN Access Server (2 free client connections for testing purposes).
proxy                         Installs proxy server for HTTP(S),FTP and other relay services (NTP, mail).
puppet                        Installs puppet upon the new guest system.
puppet-master                 Installs puppet master server.
slurmctld-master              Installs Slurm mster server and it can setup the system based on the snow.conf
slurmdbd                      Installs MySQL server and SlurmDB server. It can setup the system based on the snow.conf
snow                          Base role responsible to setup all the required clients and generate the configuration files.
snow_reference_template       Template to help sNow! users to develop their own roles quickly.
snow_template                 Role used to generate the basic image system.
swarm-manager                 Installs and setup Docker Swarm to accommodate docker based services.
swarm-worker                  Installs and setup Docker Swarm to accommodate docker based services.
syslog                        Installs a centralised Rsyslog server to consolidate the logs of the whole cluster.
torque-master                 Installs Torque and Maui. It also generates the install packages for the compute nodes.
xdm                           Installs XDM with VNC support.
```
