---
title: High Availability based on Loopback images on Shared File System
sidebar: mydoc_sidebar
tags: [ha, high_availability]
permalink: mydoc_ha_loopback_files.html
folder: mydoc
---

The following notes descrive how to setup a High Availability (HA) cluster based on loopback images for domains (Para-virtualised Xen VMs) and a BeeGFS or NFS shared file system provided by external servers.

This guide asumes that:

* You have at least two nodes to install sNow!
* You have installed the OS following the instructions defined [here](mydoc_install_os_debian.html)
* The BeeGFS (or NFS) client has been installed in sNow! nodes
* The /sNow path is mounted directly from BeeGFS/NFS or it's a mount bind to that path
* The /home path is mounted directly from BeeGFS/NFS or it's a mount bind to that path

{% include warning.html content="The /sNow and /home must be mount points. A symbolic link will not work." %}

{% include image.html file="ha_loopback_images_over_cfs.png" max-width="600" %}

## Enabling cluster file system re-export

In the following file you can define which file systems are going to be re-exported from an external server. sNow! relies NFS for deploying the compute nodes, so /sNow and /home are expected to be shared through NFSv4.

Assuming that the content of /sNow and /home are located in /beegfs the file /etc/exports.d/snow.exports should be similar to:
```
/beegfs           10.1.0.0/255.255.0.0(rw,async,fsid=0,crossmnt,no_subtree_check,no_root_squash)
```
## Enabling the /sNow path to the compute nodes
You can setup a simple mount bind to the path where /sNow folder is located in the BeeGFS, for example: /beegfs/sNow. Include the following line in the snow.conf in order to enable that.
```
MOUNT_NFS[1]="/beegfs/sNow                     /sNow          none   noauto,x-systemd.automount,x-systemd.device-timeout=60,_netdev,bind,x-systemd.requires=/beegfs/sNow   0 0"
MOUNT_NFS[2]="/beegfs/home                     /home          none   noauto,x-systemd.automount,x-systemd.device-timeout=60,_netdev,bind,x-systemd.requires=/beegfs/home   0 0"
```
## Install sNow! software
Install the first node (snow01) following the instructions defined [here](mydoc_install_os_debian.html).

Once the sNow! installation is completed in the first node, you can proceed with the other sNow! nodes installation.

Note that after installing sNow!, a reboot is required in order to boot with the new kernel and configuration.

Configure sNow! by setting snow.conf as described [here](mydoc_install_snow_conf.html)

Configure sNow! by setting active_domains.conf as described [here](mydoc_install_select_roles.html)

{% include note.html content="The SNOW_NODES defined in snow.conf must contain all the nodes of the HA cluster." %}

{% include note.html content="The gateway defined by NET_SNOW and NET_COMP in snow.conf must be setup to a virtual IP which will be setup later (i.e. 10.1.0.254)." %}

On the other nodes of the HA cluster, the ```snow init``` will deliver the following warning message.
At this point, it's safe to proceed. Please, don't consider to run this command in a production environment.
```
root@snow02:~# snow init
[W] sNow! configuration had been initiated before.
[W] Please, do not run this command in a production environment
[W] Do you want to proceed? (y/N)
```
Once all the nodes
## Install the required software packages
```
apt update
apt install libqb0 fence-agents pacemaker corosync pacemaker-cli-utils crmsh drbd-utils -y
```
Do the same in the other sNow! nodes
## Disable auto start of corosync and pacemaker
In order to avoid a death match situation, it's highly recommended to disable corosync and pacemaker to be started at boot time. To start the service, you only need to start pacemaker.
```
systemctl disable corosync
systemctl disable pacemaker
```
Do the same in the other sNow! nodes
## Setting up Corosync

### Generate keys
```
corosync-keygen
Corosync Cluster Engine Authentication key generator.
Gathering 1024 bits for key from /dev/random.
Press keys on your keyboard to generate entropy.
```
### Setup the right permissions
```
chmod 400 /etc/corosync/authkey
```
### Transfer the key to the other nodes
```
scp -p /etc/corosync/authkey snow02:/etc/corosync/authkey
```
### Configuring corosync
The content of /etc/corosync/corosync.conf should be something similar to the following example. Note that this cluster only has two nodes (snow01 and snow02).
```
# egrep -v "^$|#" /etc/corosync/corosync.conf
totem {
        version: 2
        cluster_name: snow
        token: 3000
        token_retransmits_before_loss_const: 10
        clear_node_high_bit: yes
        interface {
                ringnumber: 0
                bindnetaddr: 192.168.8.0
                mcastport: 5405
                ttl: 1
        }
}
logging {
        fileline: off
        to_stderr: no
        to_logfile: no
        to_syslog: yes
        syslog_facility: daemon
        debug: off
        timestamp: on
        logger_subsys {
                subsys: QUORUM
                debug: off
        }
}
quorum {
        provider: corosync_votequorum
        expected_votes: 2
        two_node: 1
        wait_for_all: 1
}
nodelist {
    node {
        ring0_addr: snow01
        nodeid: 1
    }
    node {
        ring0_addr: snow02
        nodeid: 2
    }
}
```
You can download the following example file and adapt it to accomodate your needs.

Edit ```/etc/corosync/corosync.conf``` in snow01 and transfer this file to the other nodes:
```
scp -p /etc/corosync/corosync.conf snow02:/etc/corosync/corosync.conf
```
Start corosync service on all the nodes
```
systemctl start corosync
```
## Xen configuration
Review if /etc/default/xendomains has an empty value for XENDOMAINS_SAVE variable or if it's commented. Otherwise, comment this variable.
### Test if Xen allows live migration between sNow! nodes
Execute the following commands in order to certify that the para-virtual machines can be migrated across the sNow! nodes:

From snow01 you can execute the following commands:
```
snow boot deploy01
xl migrate deploy01 snow02
```
If it works as expected, you should see a output message similar to the following example:
```
[4287] snow01:~ $ xl migrate deploy01 snow02
migration target: Ready to receive domain.
Saving to migration stream new xl format (info 0x0/0x0/799)
Loading new save file <incoming migration stream> (new xl fmt info 0x0/0x0/799)
 Savefile contains xl domain config
xc: progress: Reloading memory pages: 26624/524288    5%
xc: progress: Reloading memory pages: 53248/524288   10%
xc: progress: Reloading memory pages: 78848/524288   15%
xc: progress: Reloading memory pages: 105472/524288   20%
xc: progress: Reloading memory pages: 131072/524288   25%
xc: progress: Reloading memory pages: 157696/524288   30%
xc: progress: Reloading memory pages: 184320/524288   35%
xc: progress: Reloading memory pages: 209920/524288   40%
xc: progress: Reloading memory pages: 236544/524288   45%
xc: progress: Reloading memory pages: 262144/524288   50%
xc: progress: Reloading memory pages: 288768/524288   55%
xc: progress: Reloading memory pages: 315392/524288   60%
xc: progress: Reloading memory pages: 340992/524288   65%
xc: progress: Reloading memory pages: 367616/524288   70%
xc: progress: Reloading memory pages: 393216/524288   75%
xc: progress: Reloading memory pages: 419840/524288   80%
xc: progress: Reloading memory pages: 446464/524288   85%
xc: progress: Reloading memory pages: 472064/524288   90%
xc: progress: Reloading memory pages: 498688/524288   95%
xc: progress: Reloading memory pages: 524482/524288  100%
migration target: Transfer complete, requesting permission to start domain.
migration sender: Target has acknowledged transfer.
migration sender: Giving target permission to start.
migration target: Got permission, starting domain.
migration target: Domain started successsfully.
migration sender: Target reports successful startup.
Migration successful.
```
## Pacemaker

### Setup the right permissions and check the cluster health
```
chown -R hacluster:haclient /var/lib/pacemaker
chmod 750 /var/lib/pacemaker
ssh snow02 chown -R hacluster:haclient /var/lib/pacemaker
ssh snow02 chmod 750 /var/lib/pacemaker
crm cluster health | more
```
### Setup Pacemaker

The following steps can be automated taking advantage of the following script: [setup_domains_ha.sh](examples/setup_domains_ha.sh)
```bash
#!/bin/bash
domain_list=$(snow list domains | egrep -v "Domain|------" | gawk '{print $1}')
crm_attribute --type op_defaults --attr-name timeout --attr-value 120s
rm -f pacemaker.cfg
echo "property stonith-enabled=no" > pacemaker.cfg
echo "property no-quorum-policy=ignore" >>  pacemaker.cfg
echo "property default-resource-stickiness=100" >> pacemaker.cfg
echo "primitive xsnow-vip ocf:heartbeat:IPaddr2 params ip=\"10.1.0.254\" nic=\"xsnow0\" op monitor interval=\"10s\"" >> pacemaker.cfg
for domain in ${domain_list}; do
    echo "primitive $domain ocf:heartbeat:Xen \\
          params xmfile=\"${SNOW_ETC}/domains/$domain.cfg\" \\
          op monitor interval=\"40s\" \\
          meta target-role=\"started\" allow-migrate=\"true\"
         " >> pacemaker.cfg
done
echo commit >> pacemaker.cfg
echo bye >> pacemaker.cfg
crm configure < pacemaker.cfg
```
Otherwise, you can follow the next steps to setup Pacemaker:
### Define global configuration
Iniciate the setup without STONITH. The last section explains how to setup STONITH using a fence device based on Xen.
```
[4242] snow01:~ $ crm configure
crm(live)configure# property stonith-enabled=no
crm(live)configure# property no-quorum-policy=ignore
crm(live)configure# property default-resource-stickiness=100
crm(live)configure# commit
crm(live)configure# bye
```
### Define the first service in HA
Execute the ```crm configure``` and define the first service in HA as follows:
```
primitive deploy01 ocf:heartbeat:Xen \
 params xmfile="${SNOW_ETC}/domains/deploy01.cfg" \
 op monitor interval="40s" \
 meta target-role="started" allow-migrate="true"
```
Some operations like the live migration requires some extra time. Specially when the VM uses a reasonable amount of memory.
It's highly recommended to increase the default timeout to avoid cancelling the live migration due a short time limit.
The following example, setup 120s as default timeout. You can tune this value attending at your VM needs.
```
crm_attribute --type op_defaults --attr-name timeout --attr-value 120s
```
### Test!
This is a good moment to test if the HA works. In order to review that, execute in a new SSH session the command:
```
crm_mon
```
It should report something like this:
```
Stack: corosync
Current DC: snow01 (version 1.1.16-94ff4df) - partition with quorum
Last updated: Fri Jul 28 06:51:02 2017
Last change: Fri Jul 28 06:50:50 2017 by root via crm_resource on snow02

2 nodes configured
1 resource configured

Online: [ snow01 snow02 ]

Active resources:

deploy01        (ocf::heartbeat:Xen):   Started snow01
```
Using the following command, you will force to migrate the service from one node to the other one:
```
crm resource move deploy01 snow01
```
### Define all the HA services
Follow the previous instructions to setup the services required to be in HA mode. The expected outcome should be something like this:
```
Stack: corosync
Current DC: snow01 (version 1.1.16-94ff4df) - partition with quorum
Last updated: Fri Jul 28 07:13:00 2017
Last change: Fri Jul 28 07:11:31 2017 by root via cibadmin on snow01

2 nodes configured
8 resources configured

Online: [ snow01 snow02 ]

Active resources:

deploy01        (ocf::heartbeat:Xen):   Started snow01
proxy01 (ocf::heartbeat:Xen):   Started snow01
monitor01       (ocf::heartbeat:Xen):   Started snow02
nis01   (ocf::heartbeat:Xen):   Started snow02
syslog01        (ocf::heartbeat:Xen):   Started snow01
maui01  (ocf::heartbeat:Xen):   Started snow02
nis02   (ocf::heartbeat:Xen):   Started snow01
flexlm01        (ocf::heartbeat:Xen):   Started snow02
```
### Define floating IP for gateway
sNow! servers play a gateway role. The following instructions define HA for this service.
Execute the ```crm configure``` and define the ```xsnow-vip``` service as follows:
```
primitive xsnow-vip ocf:heartbeat:IPaddr2 params ip="10.1.0.254" nic="xsnow0" op monitor interval="10s"
commit
bye
```
Notice that this IP ```10.1.0.254``` must match with the IP defined in ```NET_SNOW``` and ```NET_COMP``` in the snow.conf
## Service placement
In order to balance services across the two nodes and also to distribute additional services with native HA (i.e slurm-master slurm-slave) you can use the following instructions to define the preferred hosts.
Failback is useful to define well balanced services, but if you have an ongoing issue, you could trigger a failback in a “semi-faulty” node.
```
crm(live)# configure
crm(live)configure# location cli-prefer-maui01 maui01 role=Started inf: snow01
crm(live)configure# location cli-prefer-nis01 nis01 role=Started inf: snow01
crm(live)configure# location cli-prefer-proxy01 proxy01 role=Started inf: snow01
crm(live)configure# location cli-prefer-flexlm01 flexlm01 role=Started inf: snow02
crm(live)configure# location cli-prefer-monitor01 monitor01 role=Started inf: snow02
crm(live)configure# location cli-prefer-nis02 nis02 role=Started inf: snow02
crm(live)configure# location cli-prefer-syslog01 syslog01 role=Started inf: snow02
crm(live)configure# commit
crm(live)configure# bye
```
