#!/bin/bash

### Attach a getty to the IPMI console
echo "cons:12345:respawn:/sbin/smart_agetty -L 115200 console" >> /etc/inittab
sed -i "s/console=tty0/console=tty0 console=ttyS0,115200n8/g" /boot/grub/menu.lst

### Mount NFS shared folders ###
mkdir -p /sNow/{easybuild,OS,utils}
mount -a

### Software repositories and packages ###
zypper rr 1
zypper ar -c -t yast2 -n "SUSE Linux Enterprise Server 11 SP3 DVD1" "iso:/?iso=/sNow/OS/SLES/11SP3/SLES-11-SP3-DVD-x86_64-GM-DVD1.iso" "SLES11.3_DVD1"
zypper ar -c -t yast2 -n "SUSE Linux Enterprise Server 11 SP3 DVD2" "iso:/?iso=/sNow/OS/SLES/11SP3/SLES-11-SP3-DVD-x86_64-GM-DVD2.iso" "SLES11.3_DVD2"
#zypper ar -c -t yast2 -n "SUSE Linux Enterprise Sotware Development Kit 11 SP3 DVD1" "iso:/?iso=/sNow/OS/SLES/11SP3/SLE-11-SP3-SDK-DVD-x86_64-GM-DVD1.iso" "SLE11.3_SDK_DVD1"
#zypper ar -c -t yast2 -n "SUSE Linux Enterprise Sotware Development Kit 11 SP3 DVD2" "iso:/?iso=/sNow/OS/SLES/11SP3/SLE-11-SP3-SDK-DVD-x86_64-GM-DVD2.iso" "SLE11.3_SDK_DVD2"
zypper -n --gpg-auto-import-keys ar http://download.opensuse.org/repositories/network:/cluster/SLE_11_SP3/network:cluster.repo


zypper -n --no-gpg-checks in tk git-core openssl-devel libxml2-devel libcgroup-devel libcgroup1 hwloc hwloc-devel hwloc-lstopo hwloc-doc libapr1-devel libconfuse-devel
#zypper -n in -t pattern Basis-Devel

### Install Modules ###
#rpm -ivh /sNow/OS/SLES/11SP3/extra/Modules-3.2.10-250.1.x86_64.rpm

### Install Ganglia ###
rpm -ihv /sNow/OS/SLES/11SP3/extra/libganglia-3.6.1-1.x86_64.rpm
rpm -ivh /sNow/OS/SLES/11SP3/extra/ganglia-gmond-*

mv /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.orig
ln -s /sNow/utils/gmond.conf /etc/ganglia/gmond.conf
/etc/init.d/gmond restart

### sNow profile ###
ln -s /sNow/utils/snow-source.csh /etc/profile.d/snow-source.csh
ln -s /sNow/utils/snow-source.sh /etc/profile.d/snow-source.sh

### Tunning /etc/hosts ###
cat <<EOF > /etc/hosts
127.0.0.1	localhost
192.168.7.1	genomcore2a snow01
192.168.7.2	genomcore2b
195.77.8.131	genomcore2a.upcnet.es

192.168.7.12    monitor
192.168.7.14	portal01
192.168.7.15    deploy
192.168.7.17    syslog
192.168.7.18    proxy01
192.168.7.19    flexlm01
192.168.7.25    fileserver
192.168.7.30    slurm01
192.168.7.32    nis01
192.168.7.33    nis02

192.168.7.100	snow00

192.168.7.101	n001

10.10.0.254	genomcore2a-bmc
10.10.0.253	genomcore2b-bmc
10.10.0.252	snow00-bmc
10.10.0.1	n001-bmc

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

### Install Rsyslog ###
zypper -n in rsyslog
zypper -n rm syslog-ng
cp -p /sNow/utils/rsyslog.d.remote.conf.sles /etc/rsyslog.d/remote.conf
service syslog restart

### Clone the host SSH Keys
cd /etc/ssh
tar -xf /sNow/utils/ssh_host_keys.tar
chmod u+s /usr/lib64/ssh/ssh-keysign
cp -p /etc/ssh/shosts.equiv /root/.shosts
mkdir -p /root/.ssh
cp -p /sNow/utils/.ssh/authorized_keys.root /root/.ssh/authorized_keys
cd -

#sed -i 's:#   HostbasedAuthentication no:HostbasedAuthentication yes:' /etc/ssh/ssh_config
#echo "EnableSSHKeysign yes" >> /etc/ssh/ssh_config
echo "Deploy finished : $HOSTNAME" | logger -t snow -p user.notice
