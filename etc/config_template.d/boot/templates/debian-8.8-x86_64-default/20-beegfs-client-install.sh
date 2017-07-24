#!/bin/bash

dpkg -i /sNow/common/beegfs/deb/*.deb
cp -p /sNow/common/beegfs/cfg/* /etc/beegfs
/usr/sbin/beegfs-setup-rdma
systemctl enable beegfs-helperd.service
systemctl enable beegfs-client.service

