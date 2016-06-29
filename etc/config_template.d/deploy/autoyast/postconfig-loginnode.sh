#!/bin/bash

#cloning maui binaries
cd /
tar -zxvf /sNow/OS/SLES/11SP3/MAUI/maui-3.3.1-sles11sp3.tar.gz

### Tunning /etc/fstab ###
cat <<EOF >> /etc/fstab
u005100.sw.ehu.es:/export/home   /dipc  nfs     bg,hard,intr 0 0
swoa00:/usr/local/arranque	/software/arranque	nfs 	bg,hard,intr 0 0
swoa00:/usr/local/administracion	/software/administracion	nfs 	bg,hard,intr 0 0
swoa00:/usr/local/doc	/software/doc	nfs 	bg,hard,intr 0 0
swgd00:/dipc/miscelanea	/miscelanea	nfs 	bg,hard,intr 0 0
EOF

### Tunning de /etc/hosts
cat <<EOF >> /etc/hosts

158.227.172.204 swoa00.sw.ehu.es swoa00
158.227.172.143 swgd00.sw.ehu.es swgd00
EOF

### Tunning /etc/sysconfig/network/ifcfg-eth1 ###
cat <<EOF > /etc/sysconfig/network/ifcfg-eth1
BOOTPROTO='static'
BROADCAST=''
ETHTOOL_OPTIONS=''
IPADDR='158.227.173.84/23'
MTU=''
NAME='Intel Ethernet controller'
NETWORK=''
REMOTE_IPADDR=''
STARTMODE='auto'
USERCONTROL='no'
EOF

### Bring up eth1
ifup eth1

### Create symbolic links
ln -s /sNow/easybuild/SLES11SP3/haswell/software /software

### Create mountpoints
mkdir -p /miscelanea
mkdir -p /software/doc
mkdir -p /software/administracion
mkdir -p /software/arranque
mkdir -p /dipc

### Mount NFS filesystems
mount -t nfs -a

## Create symbolic links
ln -s /software/arranque/csh.cshrc /etc/profile.d/cshrc.csh

echo "Login node customization finished on $HOSTNAME" | logger -t snow -p user.notice
