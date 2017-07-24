#!/bin/bash
MYHOSTNAME=`hostname -s`
IB_IP=`cat /sNow/snow-configspace/system_files/etc/static_hosts | grep $MYHOSTNAME-ib | awk ' { print $1 } '`

cat <<EOF >> /etc/network/interfaces

auto ib0
allow-hotplug ib0
iface ib0 inet static
        address $IB_IP
        netmask 255.255.254.0
        network 10.30.50.0
        broadcast 10.30.51.255
EOF

/etc/init.d/openibd restart
