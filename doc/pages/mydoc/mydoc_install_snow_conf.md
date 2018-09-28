---
title: sNow! Configuration File
tags:
  - configuration
  - snow.conf
keywords: "snow.conf, configuration"
last_updated: "November 30, 2016"
sidebar: mydoc_sidebar
permalink: mydoc_install_snow_conf.html
folder: mydoc
---

The sNow! configuration file (**snow.conf**) is the main configuration file of sNow! It provides a complete list of parameters which will be used to setup the HPC cluster.

A template of this file is available in ${SNOW_ETC}/snow.conf-example. In order to get started, copy the template file to ```${SNOW_ETC}/snow.conf``` and then edit snow.conf to suit your particular needs.

```
cp -p ${SNOW_ETC}/snow.conf-example ${SNOW_ETC}/snow.conf
```

Be aware that newer releases may include more parameters to setup and migrating from a previous release to a newer one will require you to extend your current snow.conf with some new parameters.

{% include warning.html content="Please ensure this snow.conf file belongs to root:root and has permissions 600 as it will contain passwords in plain text." %}

This document provides a short description of each parameter.
## NFS Server
The ```NFS_SERVER``` defines the NFS server where all the sNow! files will be stored. The /sNow filesystem is exported to the compute nodes via NFS for running the post-install scripts and for other purposes. If the NFS_SERVER matches with the sNow! server, the "snow init" command will apply the required changes in the system like adding the needed paths to /etc/exports. The default value for the NFS_SERVER is snow01 and it should be the same server you defined during installation.
## sNow! paths
The following paths define where the code and binaries are going to be stored. Most of them are NOT customizable yet but they will be in upcoming releases. Keep the following paths as static for the time being
* SNOW_ROOT: The main sNow! root directory where all the subfolders usually are stored. Default value is /sNow
```
SNOW_ROOT=/sNow
```
* SNOW_HOME: This parameter defines the default path to the shared home directory.
```
SNOW_HOME=/home
```
* SNOW_SOFT: This parameter defines the default path to the EasyBuild root folder.
```
SNOW_SOFT=$SNOW_ROOT/easybuild
```
* SNOW_SRV: This parameter defines the default path to the deployment files, templates, domains and images folder.
```
SNOW_SRV=$SNOW_ROOT/srv
```
## Domains Image
The following options define where the domains OS files will be stored. This allows you to use root and swap filesystems for the domains in LVM volumes and loopback files.
* LVM - The domains will be stored inside a Logical Volume created in the snow_vg Volume Group.
```
IMG_DST='lvm=snow_vg'
```
* Loopback files - The domains will be stored inside a loopback file located inside /sNow/srv/domains folder.
```
IMG_DST='dir=/sNow/srv/domains'
```
* NFSROOT - The domains file system will be stored in NFS server and booted via NFSROOT.
```
IMG_DST='nfs=$NFS_SERVER:/sNow/srv/domains' (experimental)
```
{% include note.html content="The NFSROOT option requires complex manual intervention and it is still experimental." %}
## sNow! Nodes
Defines the list of nodes which will be the sNow! management servers. The default value is snow01. If you use more than one sNow! management server then you should define here the list of hostnames in a space separated list.
Example:
```
SNOW_NODES=( snow01 snow02 )
```
## Master Password
Defines the master password which will be used for setting up the root password for the deployed domains and compute nodes. It’s also the default password for the services installed in the domains (MySQL, LDAP, Slurm, etc.). We strongly recommend changing the default value which is ```MASTER_PASSWORD='HPCN0w!!'```.
## sNow! user definition
Defines all the parameters of the snow user and group.
```
sNow_GID=2000
sNow_GROUP=snow
sNow_UID=2000
sNow_USER=snow
```
## HPCNow! user definition
Defines all the parameters of the hpcnow user.
```
HPCNow_UID=2001
HPCNow_GID=2000
HPCNow_USER=hpcnow
```
## Admin Users
Defines a list of admin users eligible to access via SSH to the domains and deployed compute nodes from the sNow! nodes. The default value is ADMIN_USERS="root snow"
## Admin Groups
Defines a list of admin groups eligible to access via SSH to the domains and deployed compute nodes from the sNow! nodes. The default value is ADMIN_GROUPS="root snow"
## Source control and continuous integration support
The following parameters allow you to integrate the key configuration files, deployment scripts and other key codes located in ${SNOW_SRV} with your source control system. It supports GitHub and BitBucket through OAuth tokens. The default values are empty.
This is key to enabling continuous integration support and testing changes in a testing environment before to merging them into  production.
Since the data contained in this folder is extremely sensitive, the GIT repository MUST be private. Since BitBucket allows you to use private repositories for free, we suggest to explore this option. More information about how to setup OAuth integrated applications is available in the GitHub and BitBucket websites.
Example:
```
PRIVATE_GIT_TOKEN=t54skl3333xxxxxxxxxxyyyy3333333srgrafsiJ
PRIVATE_GIT_REPO=bitbucket.org/YOUR_ACCOUNT/snow-configspace.git
```
## Network setup
sNow! is able to manage six different networks. The network bridges must be configured before initializing the configuration with "snow init".
The following parameters define the required information to setup those networks in the domains and compute nodes. All networks are defined with the form:
```
NET_XXX=( 'Bridge' 'Gateway' 'First IP' 'Network Netmask' 'Hostname extension' )
```
Where:
* Bridge: The name of the network bridge associated to this network
* Gateway: The default GW for this network
* First IP: The first IP address in the rank
* Network: The first three octets of the network followed by a dot
* Netmask: The network mask for this network
* Hostname extension: The extension used for name resolution, for example you may want n001 to resolve to the ETH and n001-ib to resolve to the IB network.
The ```NET_PUB``` network is the external network, usually available only in the snow admin nodes.
```
NET_PUB=( 'xpub0' '82.98.134.254' '' '82.98.134.' '255.255.255.0' '-pub' )
```
The ```NET_SNOW``` network is the cluster management internal network. It is usually a 1 GbE network used for deploment, SSH among nodes, BATCH manager control of the nodes, etc.
```
NET_SNOW=( 'xsnow0' '192.168.0.1' '192.168.0.1' '192.168.0.' '255.255.0.0' '' )
```
The ```NET_COMP``` network is a subnetwork of NET_SNOW which only contains compute nodes. This network is managed by the sNow! CLI through the DHCP server.
```
NET_COMP=( 'xsnow0' '192.168.0.1' '192.168.1.1' '192.168.1.' '255.255.0.0' '' )
```
The ```NET_MGMT``` network is the network of the baseboard management interfaces. Depending on which hardware you have acquired they are called IPMI (generic) or iLO (HP) or iDRAC (Dell) or IMM  (IBM/Lenovo).
```
NET_MGMT=( 'xmgmt' '10.0.0.1' '10.0.1.1' '10.0.0.' '255.255.0.0' '-mgmt' )
```
The ```NET_LLF``` is the low latency fabric network. If you don't use an Infiniband, OPA or other high speed network, just comment the following line:
```
NET_LLF=( 'xllf0' '10.1.0.1' '10.1.1.1' '10.1.0.' '255.255.0.0' '-ib' )
```
The ```NET_DMZ``` network is an optional network which allows you to expose some services to the public network. It may require you to apply some rules in your institutional firewall or to setup a local firewall in the sNow! management server.
If you want to use it uncomment it and check the sNow! Administration Guide on how to use it.
```
NET_DMZ=( 'xdmz0' '172.16.1.254' '172.16.1.1' '172.16.1.' '255.255.255.0' '-dmz' )
```
## IPMI / BMC setup
The following parameters provide the required information to interact with the compute nodes via IPMI.Please define here the access type for the IPMI/iLO/iDRAC/IMM of your system and the username and password which allow interaction with it. In the present version of sNow! all nodes must have the same user/password combination.
* ```IPMI_TYPE```: IPMI type used by ipmitools. Default value is lanplus.
* ```IPMI_USER```: IPMI user. Default value is admin.
* ```IPMI_PASSWORD```: IPMI password associated with the user described above. Default value is admin.
## Power awareness considerations
The following parameters will define how the nodes will boot in case you boot a large set of nodes. Instead of booting them all at exactly the same time, and in order to avoid unnecessary circuit overload and unbalanced loading in the power distribution, the nodes will be booted in blocks.
* ```BLOCKN```: Number of nodes to boot per cycle. Default value is 12 nodes.
* ```BLOCKD```:Delay before booting the next group of BLOCKD nodes. Default value is 4 seconds.
* ```BOOT_DELAY```: The expected time for the compute node to start to boot from PXE. After this period of time, the PXE configuration will roll back to the default boot defined in the snow.conf. Default value is 300 seconds.

{% include note.html content="iThis means if you boot a range of 100 nodes it will boot BLOCKN nodes, then wait BLOCKD seconds, boot BLOCKN more nodes, wait BLOCKD seconds, and repeat this sequence until all of them are booted." %}
## DHCP Network Interface
The sNow! domain NIC that will be used for serving DHCP and PXE to the compute nodes is defined by ```DHCP_NIC```. If your sNow! implementation supports eIPoIB and your compute nodes allows booting from PXE over Infiniband, you may want to update this value in order to accelerate the boot process.
```
DHCP_NIC=eth0
```
## Config manager
sNow! allows you to integrate your prefered configuration manager. If you are using CFEngine, there is a role which partially integrates it. If you are using another one, you may want to create a new role. Since configuration managers are quite complex to setup and strongly depend on site implementation, this component is outside the sNow! scope and support. sNow! only provides integration but not deployment of this service. The default values are unset.
* ```CM_SOFTWARE```: Defines the name of the configuration manager to be used. Default value is empty.
* ```CM_SERVER```: Defines the configuration manager server. Default value is empty.
* ```CM_VERSION```: Defines the version of the configuration manager to be used. Default value is empty.
## Cluster provisioning: deployment system
The following parameters define the information required to deploy and boot new compute nodes as well as the golden nodes which will play a key role in the deployment of applications in the shared file system as well as the cloning system.
* ```DEFAULT_BOOT```: All the nodes will boot via PXE and the PXE server will define when the node should boot from the network or any other device. You can setup a default image here or define different images for a specific nodes through snow CLI. The default value is localboot.
* ```DEFAULT_TEMPLATE```: By default sNow! will deploy all the compute nodes with the template defined in this parameter. You can also deploy nodes using a different template by adding the template name as an option in the snow CLI:
```
snow deploy n-[001-200] custom_template
```
More information on this is available in section 6. The default value is centos-7-default
* ```DEFAULT_CONSOLE_OPTIONS```: Some compute nodes may require different options in order to interact with the remote console during the PXE boot. This option is used as default. You can also setup different console options for a specific node through snow CLI. The default value is:
```
DEFAULT_CONSOLE_OPTIONS="console=tty0 console=ttyS0,115200n8"
```
## Clusters
sNow! can manage multiple clusters and architectures. For easier administration, each architecture should define a new cluster. This parameter contains a list of the clusters that sNow! will manage. From the sNow! point of view, each group of nodes using a different architecture defines a new cluster, so each architecture must have a different name unless you want to reuse the same binaries and libraries in newer architectures (strongly not recommended). The syntax is :
```
CLUSTERS=([clustername01]="computenode_prefix[01-99]" [mycluster02]="hsw[01-99]")
```
Example:
```
CLUSTERS=([mycluster01]="knl[01-99]" [mycluster02]="hsw[01-99]")
```
## Golden Nodes
When setting up a cluster there are actions which only need to be performed once per cluster. This parameter defines which nodes these actions are to be performed on. In the case of very heterogeneous architectures allocated in the same cluster, these actions may need to be performed once per architecture. This is for example the case of EasyBuild installation which will be required to run once per each architecture.
```
GOLDEN_NODES=( knl-01 hsw-01 skl-01 )
```
## Main downloader tool
The main downloader tool in sNow! is wget, but we recommend you to try axel, which accelerates the process quite significantly when compared to standard wget. There are two options implemented axel and wget.
```
DOWNLD=wget
```
## Locales
Update the following parameters in order to support compatibility with your keyboard and timezone.
```
LANG=en_US
KEYMAP=us
TIMEZONE=Europe/Amsterdam
```
## Mandatory network parameters and services required by sNow!
The following parameters must be setup in order to deploy and use the cluster properly. The DNS servers are used by the deploy role to setup the internal DNS.
```
DNS_SERVERS=8.8.8.8,8.8.4.4
DOMAIN=in.hpcnow.com
```
## Optional network services provided by the site/institution
sNow! provides easy integration with your existing environment through the SITE_SERVICES variables. The following parameters define integration with standard services usually required by an HPC cluster. Other services can be integrated via hooks (see section 12 of the sNow! administrator documentation).
```
SITE_PROXY_SERVER=192.168.7.1
SITE_PROXY_PORT=8080
SITE_NTP_SERVER=192.168.7.1
SITE_LDAP_SERVER=192.168.7.1
SITE_LDAP_URI="ldap://ldap01.hpcnow.com, ldap://ldap02.hpcnow.com"
SITE_LDAP_TLS=FALSE
SITE_LDAP_PROTO=ldap
SITE_LDAP_BASE="dc=in,dc=hpcnow,dc=com"
SITE_MAIL_SERVER=smtp.gmail.com::587
SITE_MAIL_USER=
SITE_MAIL_PASSWORD=
SITE_SYSLOG_SERVER=192.168.7.1
```
## Shared file system support
sNow! supports integration with the most popular shared filesystems in HPC environments via hooks. sNow! has native support for NFS clients. If you are using a different shared file system, then the $SNOW_ROOT and $HOME must be available in the sNow! management nodes and some node(s) must re-export those file systems through NFS.
### NFS clients
The NFS mounts can be defined in a BASH array element format, where each mount is identified with a unique number from 1 to 100. Remember that you will need to update the /etc/exports in your server and reload the NFS configuration with “exportfs -ra”.
```
MOUNT_NFS[N]="nfs-server:/shared_folder    /shared_folder   nfs    bg,tcp,defaults 0 0"
```
Example:
```
MOUNT_NFS[3]="snow01:/projects             /projects        nfs    bg,tcp,defaults 0 0"
```
If NFS is your main shared file system, then the following two lines become mandatory, as they define the required mount points for $SNOW_ROOT and $HOME, which are needed for sNow! to function correctly.
```
MOUNT_NFS[1]="${NFS_SERVER}:${SNOW_ROOT}        ${SNOW_ROOT}   nfs    bg,tcp,defaults 0 0"
MOUNT_NFS[2]="${NFS_SERVER}:${SNOW_HOME}        ${SNOW_HOME}   nfs    bg,tcp,defaults 0 0"
```
## Slurm configuration
The following parameters will help you to setup and configure a production ready Slurm Workload Manager. For more information please visit the Slurm website.
### Slurm Database
```
SLURMDBD_USER=slurm
SLURMDBD_PASSWORD=whatever
SLURMDBD_NAME=slurm_acct_db
```
### Slurm Accounting and Fair Share
The following option forces the use of associations and QoS for accounting.
```
ACCOUNTING_STORAGE_ENFORCE=associations,qos
```
Fairsharing is the most common approach to share resources but it requires some manual intervention. Consider using the following helper script to define how to share the computational resources between your groups and users:
```
$SNOW_ROOT/contrib/slurm_fairshare/slurm_share_tree.sh
```
If you you don't need QoS or fairshare, you can consider to implement one of the two following options:

* nojobs - This option prevents job information being stored in accounting.
* nosteps - This option prevents step information being stored in accounting.

{% include note.html content="Both nojobs and nosteps could be helpful in an environment where you want to use limits but don't really care about utilization. For more information, please see : https://slurm.schedmd.com/accounting.html" %}
```
ACCOUNTING_STORAGE_ENFORCE=nojobs
```
### Cluster Name
The following parameter defines the name of the cluster.
```
SLURM_CLUSTER_NAME
```
### MUNGE and Slurm user definition
```
MUNGE_UID=994
MUNGE_GID=994
SLURM_GID=995
SLURM_UID=995
```
### Slurmctl master
```
SLURM_VERSION=15.8.2
SLURM_CONF=/etc/slurm/slurm.conf
LICENSES=intel*2,matlab*200,fluent*5000
```
### Slurm compute nodes
The following lines define multiple subsets of nodes using Slurm syntax. More information on this is available in the Slurm documentation.
```
SLURM_NODES[1]="NodeName=knl[01-99] RealMemory=128000  Sockets=2  CoresPerSocket=72 ThreadsPerCore=4 State=UNKNOWN"
SLURM_NODES[2]="NodeName=hsw[01-99] RealMemory=256000  Sockets=2  CoresPerSocket=12 ThreadsPerCore=1 State=UNKNOWN"
SLURM_NODES[3]="NodeName=skl[01-99] RealMemory=512000  Sockets=4  CoresPerSocket=24 ThreadsPerCore=1 State=UNKNOWN"
```
### Slurm partitions
The following lines define multiple partitions using the Slurm syntax. More information is available in the Slurm documentation.
```
SLURM_PARTITION[1]="PartitionName=high    Nodes=knl[01-99],hsw[01-99],skl[01-99]  Default=NO  Shared=FORCE:1 Priority=100 MaxTime=6:00:00   PreemptMode=off"
SLURM_PARTITION[2]="PartitionName=medium  Nodes=knl[01-99],hsw[01-99],skl[01-99]  Default=NO  Shared=FORCE:1 Priority=75  MaxTime=72:00:00  PreemptMode=off"
SLURM_PARTITION[3]="PartitionName=requeue Nodes=knl[01-99],hsw[01-99],skl[01-99]  Default=NO  Shared=NO      Priority=50  MaxTime=24:00:00  PreemptMode=requeue    GraceTime=120"
SLURM_PARTITION[4]="PartitionName=low     Nodes=knl[01-99],hsw[01-99],skl[01-99]  Default=YES Shared=FORCE:1 Priority=25  MaxTime=168:00:00 PreemptMode=suspend"
```
