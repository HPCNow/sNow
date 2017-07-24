#!/bin/bash
/sNow/common/ofed-debian/MLNX_OFED_LINUX-4.0-2.0.0.1-debian8.3-x86_64/uninstall.sh -q
/sNow/common/ofed-debian/MLNX_OFED_LINUX-4.0-2.0.0.1-debian8.3-x86_64/mlnxofedinstall --without-fw-update -q
systemctl enable openibd
mkdir /root/ofedinstlog
cp -r /tmp/* /root/ofedinstlog
