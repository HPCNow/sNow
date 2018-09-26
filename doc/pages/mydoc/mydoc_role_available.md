---
title: Available Roles
tags: [domains, roles, vms, vm, containers]
keywords: includes, conref, dita, transclusion, transclude, inclusion, reference
last_updated: July 3, 2016
summary: "This section explains what services are installing each role. It also provides information regarding protocols used and configuration files used."
sidebar: mydoc_sidebar
permalink: mydoc_role_available.html
folder: mydoc
---

## builder                       
This role deploys a minimal OS suitable for compiling code and generating Debian packages.
## cfengine                      
Installs CFEnfine on the new guest system. Since configuration managers are quite complex to set up and strongly depend on the site implementation, this component is outside the scope of sNow! and sNow! support. sNow! only provides integration but not deployment of this service. The default values are unset.
More information regarding cfengine is available here: https://docs.cfengine.com/docs/3.5/manuals-writing-policy-configuration-file-structure.html

Key parameters in snow.conf


|Parameter|Function|
|---------|--------|
|CM_SOFTWARE|Used to define the name of the configuration manager to be installed. Default value is empty|
|CM_SERVER|Used to define the configuration manager server. Default value is empty.|
|CM_VERSION|Used to define the version of the configuration manager to be installed. Default value is empty.|

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/var/cfengine/inputs/promises.cf|X|This file is the first file that cf-agent with no arguments will try to look for. It should contain all of the basic configuration settings, including a list of other files to include. In normal operation, it must have a bundlesequence.|
|/var/cfengine/inputs/update.cf|X|This file should rarely if ever change. Should you ever change it (or when you upgrade CFEngine), take special care to ensure the old and new CFEngine can parse and execute this file successfully.|
|/var/cfengine/inputs/failsafe.cf|X|This file is generated during the bootstrapping process and should probably never be changed. The only job of failsafe.cf is to execute the update bundle in a “standalone” context should there be a syntax error somewhere in the main set of promises.|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/5308 | cfengine | Default port for the CFEngine server |

## cfs                           
Allows the setup of the NFS client and some cluster file system clients (experimental) in the domains. sNow! has native support for NFS clients and the NFS mounts can be defined in the snow.conf. The integration with other cluster file systems is considered experimental.
More information available in the snow.conf man pages.

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|MOUNT_NFS[n]    | Used to define the mount point and options in /etc/fstab for NFS clients |
|MOUNT_BEEGFS[n] |Used to define the mount point and options in /etc/fstab for BeeGFS clients |
|MOUNT_LUSTRE[n] |Used to define the mount point and options in /etc/fstab for Lustre clients |
|MOUNT_GPFS[n]   |Used to define the mount point and options in /etc/fstab for GPFS clients |

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/beegfs/beegfs-mounts.conf|-|Defines the BeeGFS client setup|

## deploy                        
The role “deploy” configures Dnsmasq to provide PXE, TFTP, DHCP and DNS. Those services are also integrated with sNow! CLI in order to deploy systems with kickstart (RHEL/CentOS), pressed (Debian/Ubuntu) and autoyast (SuSE) based on predefined templates. It also interacts with the sNow! CLI to generate and boot diskless images based on previously deployed systems.
The role also installs the fishermac utility, which simplifies the “painful” process of collecting MAC addresses from the compute nodes. This utility allows populating /etc/ethers, which contains the table of IPs and MAC addresses used by dnsmasq to identify each node.

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|NET_COMP|Used to define the dnsmasq.conf parameters|
|DEFAULT_BOOT|Used to define the default boot option for the compute nodes|
|DEFAULT_TEMPLATE|Used to define the default template to deploy the compute nodes|

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/ethers|$SNOW_SRV/deploy_files/etc/ethers|IP and MAC addresses table|
|/etc/hosts|$SNOW_SRV/deploy_files/etc/static_hosts|IP and hostname table|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/53, UDP/53|DNS|DNS|
|UDP/67-68|DHCP|DHCP|
|TCP/69, UDP/69|TFTP|TFTP|

## docker
Installs and sets up Docker Community Edition to accommodate Docker based services. You will need to follow the standard proceedures to deploy, initialize and manage Docker containers in the domains deployed with this role. If you have a complex workflow or a large set of Docker containers, consider using Docker Swarm roles described below.
As the system doesn’t know what services are going to be allocated in that domain, no firewall filters will be applied.
More information regarding Docker management is available here: https://docs.docker.com/get-started/

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|DOCKER_VERSION|Used to define the version of Docker to be installed|

## gdm                           
Installs GDM and LXDE with VNC support in order to provide a remote graphical user interface. In combination with the login and cfs roles, this role can setup an interactive environment to support the virtual laboratory needs for the end users with tasks including long term pre and post-processing through a GUI.

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/5900+|VNC|Virtual Network Computing (VNC)|

## ldap-master                   
Installs an LDAP server from scratch. This role requires certificates by default. If you don’t have these certificates already, you can follow the process described in the section "How to create custom LDAP certificates".

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|LDAP_ADMIN_PASSWORD|Ldap Admin password. Defaults to admin|
|LDAP_CONFIG_PASSWORD|Ldap Config password. Defaults to config|
|LDAP_ORGANIZATION|LDAP organization name. By default is the domain name defined with $DOMAIN|
|LDAP_PPOLICY_DN_PREFIX|Variables used to define additional policies and schemas. Default value is unset|
|LDAP_ADDITIONAL_SCHEMAS||
|LDAP_ADDITIONAL_MODULES||


Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/ldap/slapd.d/* | $SNOW_SRV/deploy_files/etc/ldap/*| LDAP configuration files|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/389|LDAP|LDAP|
|TCP/636|LDAPS|LDAP|

## login                         
The domains deployed with this role are just “landing” nodes, which are meant to be used for performing administrative tasks on the shared file system and to manage jobs. Computational or IO intensive tasks must be performed on the compute nodes through the batch system or through the interactive command line. More information about interactive command is available in the Appendix.
In order to avoid confusion for the end user, development tools and Lmod (modules) are not available.
This role uses two SSH instances, one for enabling access to admin users like root, snow from the snow servers and another one for the regular users (not root).

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/ssh/sshd_config.pub | $SNOW_SRV/deploy_files/etc/ssh/sshd_config.pub | Used to define the SSH daemon configuration to be exposed on the public network.|


Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/22|SSH|Filtered by root and admin users and host : snow servers|
|TCP/22022|SSH|Open to any users except root|

## minimal                       
Based on the functional role “snow”, this role also removes some unnecessary packages. This role is meant to be used to deploy software which does not need to interact with other services.
monitor                       
This role deploys gmetad to consolidate all the metrics gathered by gmond on the compute nodes and across the domains. It represents the data with the Ganglia Web Frontend.

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|etc/ganglia-webfrontend/apache.conf|$SNOW_SRV/deploy_files/etc/ganglia-webfrontend/apache.conf|Used to setup the Apache web server for Ganglia Web Frontend.|
|/etc/ganglia/gmetad.conf|$SNOW_SRV/deploy_files/etc/ganglia/gmetad.conf|Used to setup the Gmetad.|
|/etc/ganglia/gmond_${cluster}.conf|$SNOW_SRV/deploy_files/etc/ganglia/gmond_${cluster}.conf|Used to setup Gmond and collect the metrics consolidated for each cluster.|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/80|HTTP|Ganglia Web Frontend|
|TCP/8650-86XX|GMOND|Gmond (each cluster has a dedicated port)|

## opennebula-frontend
sNow! can deploy OpenNebula Frontend servers and re-architect compute nodes to OpenNebula hypervisor nodes.

{% include note.html content="In order to enable OpenNebula, you must define the version to be used" %}
{% include note.html content="OpenNebula integration is not available for SuSE and OpenSuSE" %}

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|OPENNEBULA_VERSION| define the version to be used|
|OPENNEBULA_DB_NAME|Used to define the default database of OpenNebula|
|OPENNEBULA_USER| Used to define the admin user of OpenNebula|
|OPENNEBULA_PASSWORD| Defines the password of the OpenNebula user|

## openvpn_as                    
This role deploys OpenVPN Access Server (two free client connections for testing purposes). OpenVPN Access Server is a full featured secure network tunneling VPN software solution that integrates OpenVPN server capabilities, enterprise management capabilities, simplified OpenVPN Connect UI, and OpenVPN Client software packages that accommodate Windows, MAC, Linux, Android, and iOS environments.
OpenVPN Access Server supports a wide range of configurations, including secure and granular remote access to internal and/ or private cloud network resources and applications with fine-grained access control.
Learn more about this software here: https://openvpn.net/index.php/access-server/docs.html

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|MASTER_PASSWORD|Used to define the default admin password of the OpenVPN Access Server web interface|

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/openvpn_as|$SNOW_SRV/deploy_files/etc/openvpn_as|Files used to setup the OpenVPN Access Server|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/443|HTTPS|OpenVPN daemon will automatically route browser traffic to TCP 943 by default.|
|TCP/943|HTTP(s)|Port where the web server interface is listening by default.|
|UDP/1194|VPN|OpenVPN|

## proxy                         
This role deploys a transparent proxy server based on Squid for HTTP(S),FTP and also relay servers for NTP and SMTP (Exim).
More information regarding Squid is available here: http://www.squid-cache.org/Doc/
More information regarding Exim is available here: http://www.exim.org/docs.html

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|SITE_MAIL_SERVER|Used to define the server that will send emails. It allows you to setup a Gmail account as relay server.|
|SITE_MAIL_USER|Used to setup the user credentials for the real email server|
|SITE_MAIL_PASSWORD|Used to setup the user credentials for the real email server|

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/ntp.conf|SNOW_SRV/deploy_files/etc/ntp_server.conf|Defines the NTP server configuration|
|/etc/squid3/*|$SNOW_SRV/deploy_files/etc/squid3/*|Files that defines the Squid (proxy server) configuration|
|/etc/exim4/*|$SNOW_SRV/deploy_files/etc/exim4/*|Files that defines the Exim email relay server|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/25|SMTP|Exim|
|TCP/123|NTP|NTP|
|TCP/8080|Proxy|Transparent proxy for HTTP, HTTPS, FTP|

## puppet                        
Installs puppet upon the new guest system. Since configuration managers are quite complex to setup and also strongly depend on site implementation details, this component is outside the scope of sNow! and sNow! support. sNow! only provides the integration of this service and not its deployment and configuration.

## puppet-master                 
Installs puppet master server. Since configuration managers are quite complex to setup and also strongly depend on site implementation details, this component is outside the scope of sNow! and sNow! support. sNow! only provides the integration of this service and not its deployment and configuration.

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/8140|puppet|Puppet Master default port|


## slurmctld-master              
This role deploys and installs the Slurm master server and is configured based on the parameters available in snow.conf
Slurm is one of the most popular job scheduling systems.  It is open-source, fault-tolerant, and highly scalable, suitable for small to very large Linux clusters.
As a cluster workload manager, Slurm has three key functions. First, it allocates exclusive and/or non-exclusive access to resources (compute nodes) to users for some duration of time so they can perform work. Second, it provides a framework for starting, executing, and monitoring work (normally a parallel job) on the set of allocated nodes. Finally, it handles the contention for resources by managing a queue of pending work. Optional plugins can be used for accounting, advanced reservation, gang scheduling (time sharing for parallel jobs), backfill scheduling, topology optimized resource selection, resource limits by user or bank account, and sophisticated multifactor job prioritization algorithms.

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|SLURM_VERSION|Used to define the version of Slurm to be installed. By default it installs the latest version available in the HPCNow! repository.|
|SLURM_CONF|Used to define the path to the main Slurm configuration file|
|SLURM_GID||
|SLURM_UID|Used to define user GID and UID parameters|
|LICENSES|Used to define the number of licenses available for end user software packages|
|SLURM_NODES[n]|Used to define Slurm compute nodes|
|SLURM_PARTITION[n]|Used to define Slurm partitions|

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/munge/munge.key|$SNOW_SRV/deploy_files/etc/munge/munge.key|Munge key file|
|/etc/slurm/*|$SNOW_SRV/deploy_files/etc/slurm/*|Set of slurm configuration files|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/6817|slurmctld|Slurm Controller Daemon|


## slurmdbd                      
This role deploys and installs MySQL server and SlurmDB server in order to support the slurmctld-master role defined above.

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|SLURMDBD_USER|Used to define the user which runs the Slurm DB daemon|
|SLURMDBD_PASSWORD|Used to define the password of the MySQL database|
|SLURMDBD_NAME|Used to define the name of the MySQL database|
|ACCOUNTING_STORAGE_ENFORCE|Used to enforce limits defined in the Slurm database and also defines the information to be stored|
|SLURM_CLUSTER_NAME|Used to define the name of the Slurm cluster|


Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/slurm/slurmdbd.conf|$SNOW_SRV/deploy_files/etc/slurm/slurmdbd.conf|Slurm DB configuration file|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/6819|slurmdbd|Slurm Database Daemon|

## snow                          
This role is responsible for setting up all the required clients and generating the configuration files. It is the default role that defines an operational domain, so any other role is executed after the snow role in order to guarantee the consistency across all the domains and services.

sNow! provides easy integration with your existing environment through the use of SITE_SERVICES variables. The following parameters define integration with the standard services usually required by a HPC cluster. Other services can be integrated via hooks (see Section 12 of sNow! documentation).

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|SITE_PROXY_SERVER||
|SITE_PROXY_PORT|Used to define the institutional proxy server and the port available|
|SITE_NTP_SERVER|Used to define the institutional NTP server|
|SITE_LDAP_SERVER||
|SITE_LDAP_URI||
|SITE_LDAP_TLS||
|SITE_LDAP_PROTO||
|SITE_LDAP_BASE|Used to define the institutional LDAP server and associated parameters|
|SITE_MAIL_SERVER||
|SITE_MAIL_USER||
|SITE_MAIL_PASSWORD|Used to define the institutional email server and associated parameters|
|SITE_SYSLOG_SERVER|Used to define the institutional proxy server|

## snow_reference_template       
Template to help sNow! users develop their own roles quickly.

## swarm-manager
Installs and sets up the Docker Swarm Manager to accommodate Docker based services.
This role installs Portainer by default, which is a simple management solution for Docker. It consists of a web UI that allows you to easily manage your Docker containers, images, networks and volumes. In addition to that, the role also deploys “hello-world” Docker containers which are populated and replicated across all the swarm workers.

Important note: Portainer requires you to setup a password the first time you initiate the service. Please access the Portainer allocated in your swarm-manager domain and setup the admin password before to move the service to production.

Since the system doesn’t know what services are going to be allocated in that domain, no additional firewall filters will be applied.

General information regarding Docker Swarm is available here: https://docs.docker.com/engine/swarm/
More information regarding the swarm mode routing mesh is available here: https://docs.docker.com/engine/swarm/ingress/
More information regarding swarm for production is available here: http://docs.master.dockerproject.org/swarm/plan-for-production/

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/9000|HTTP|Access to Portainer|

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/root/docker-compose.yml|${SNOW_SRV}/deploy_files/etc/docker-compose.yml|Contains all the containers to be deployed. If nothing is available in ${SNOW_SRV}it will install a few examples and Portainer.|
|/root/docker_swarm.token|$SNOW_SRV/deploy_files/etc/docker_swarm.token|This file contains the token generated once the swarm manager boots for first time.|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/2377|Swarm|Used for Swarm cluster management communications|
|TCP,UDP/7946|Container discovery|Used for communication among Swarm nodes|
|UDP/4789|Overlay network|Used for overlay network traffic|
|TCP/2376|Engine daemon|Swarm Engine daemon for TLS|
|TCP/3376|Swarm manager|Swarm manager for TLS|
|TCP/2375|Docker Engine|Docker Engine CLI commands directed to the Engine daemon|
|TCP/3375|Engine daemon|Engine CLI commands to the Swarm manager.|

## swarm-worker
Installs and sets up Docker Swarm workers to accommodate Docker based services. The nodes deployed with this role will join the existing Swarm Manager automatically. Before deploying any Swarm worker domain you will need to boot the Swarm Manager domain and ensure that the services are up and running (for example visiting the Portainer UI).

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/root/docker_swarm.token | $SNOW_SRV/deploy_files/etc/docker_swarm.token | This file contains the token generated once the Swarm Manager boots for first time.|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/2377| Swarm |Used for Swarm cluster management communications|
|TCP,UDP/7946|Container discovery|Used for communication amongst Swarm nodes|
|UDP/4789|Overlay network|Used for overlay network traffic|

## syslog                        
This role is responsible for installing and setting up a central RSYSLOG server which consolidates all the cluster logs, including the sNow! domains and compute nodes. RSYSLOG stands for rocket-fast system for log processing. It offers high-performance, great security features and a modular design. RSYSLOG is able to accept inputs from a wide variety of sources, transform them and output the results to a variety of  destinations. RSYSLOG can deliver over one million messages per second to local destinations when limited processing is applied.

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/rsyslog.conf|$SNOW_SRV/deploy_files/etc/rsyslog.conf|Setup Rsyslog daemon|

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/514|rsyslog|Default port for the RSYSLOG logging server|

## torque-master
This role is responsible for installing and setting up the TORQUE workload manager and generates the install packages for the compute nodes. TORQUE stands for “Terascale Open-source Resource and QUEue Manager” and it is a distributed resource manager which provides control over batch jobs and distributed compute nodes. TORQUE can integrate with the non-commercial Maui Cluster Scheduler or the commercial Moab Workload Manager to improve overall utilization, scheduling and administration on a cluster. This role also installs Maui Cluster Scheduler if the TORQUE version is compatible with Maui.

Important note: At the time of writing, Maui 3.3.2 is not compatible with the latest stable version of TORQUE 6.1.1.1. In order to have Maui and TORQUE working, you should should consider installing TORQUE 5.1.3.

{% include tip.html content="It's good practice to run a backup of the configuration. Consider including the following command in the crontab of your sNow! server: <br/>
<pre>ssh ${TORQUE_MASTER} /usr/local/bin/qmgr -c 'p s' > $SNOW_SRV/deploy_files/etc/torque/torque.conf</pre> "%}

Key parameters in snow.conf

|Parameter|Function|
|---------|--------|
|TORQUE_VERSION|Used to define the version of TORQUE to be installed|
|MAUI_VERSION|Used to define the version of Maui to be installed|

Key configuration files:

|domain|snow-configspace|Function|
|------|----------------|--------|
|/etc/torque/torque.conf|$SNOW_SRV/deploy_files/etc/torque/torque.conf|Dump of the TORQUE configuration|
|/usr/local/maui/maui.cfg |$SNOW_SRV/deploy_files/etc/maui/maui.cfg|The main Maui configuration file |

Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/15004|pbs_server|Default port for PBS server|


## xdm                           
Installs XDM and LXDE with VNC support in order to provide a remote graphical user interface. In combination with the login and cfs roles, this role can setup an interactive environment to support the virtual laboratory needs for the end users with tasks including long term pre and post-processing through a GUI.


Default ports

| Port | Service | Function |
|------|---------|----------|
|TCP/5900+ | VNC| Virtual Network Computing (VNC) |
