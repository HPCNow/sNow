---
title: Domains Power Control
keywords: power control, domains
last_updated: March 20, 2016
summary: "This section explains how to boot, shutdown and reboot sNow! domains"
sidebar: mydoc_sidebar
permalink: mydoc_domain_power_control.html
folder: mydoc
---

## Boot
Once you have deployed all domains, you can boot them all by running the following command:
```
snow boot domains
```
Otherwise, if you want to boot an specific domain, you can run the following command:
```
snow boot <domain_name>
```
## Automatic Boot (single sNow! server only)
If you want your domains to run automatically when the snow01 system is rebooted, just add links to their XEN config files to the /etc/xen/auto directory. You will find the config files on ${SNOW_ETC}/domains.
```
# ls -l
lrwxrwxrwx 1 root root   41 nov 13 20:13 deploy01.cfg -> ${SNOW_ETC}/domains/deploy01.cfg
lrwxrwxrwx 1 root root   40 nov  9 10:38 login01.cfg -> ${SNOW_ETC}/domains/login01.cfg
lrwxrwxrwx 1 root root   42 jul 28 13:11 monitor01.cfg -> ${SNOW_ETC}/domains/monitor01.cfg
lrwxrwxrwx 1 root root   40 jul 28 13:11 proxy01.cfg -> ${SNOW_ETC}/domains/proxy01.cfg
lrwxrwxrwx 1 root root   40 jul 28 13:11 slurm01.cfg -> ${SNOW_ETC}/domains/slurm01.cfg
lrwxrwxrwx 1 root root   42 jul 28 13:11 slurmdb01.cfg -> ${SNOW_ETC}/domains/slurmdb01.cfg
lrwxrwxrwx 1 root root   41 jul 28 13:11 syslog01.cfg -> ${SNOW_ETC}/domains/syslog01.cfg
```
## Automatic Boot (sNow! server in HA cluster mode)
The domains are automatically initiated when sNow! is operating as High Availability cluster. More information available in the [Scalability and High Availability](mydoc_ha_overview.html) section.

## Boot all domains (single sNow! server only)
The following command allows booting all domains. This function is not available in sNow! HA because the services are managed by the HA software.
```
snow boot domains
```
## Reboot
The following command allows rebooting a specific domain:
```
snow reboot <domain>
```
## Reset
The following command forces rebooting a specific domain:
```
snow reset <domain>
```
## Shutdown
The following command allows shutting down a specific domain:
```
snow shutdown <domain>
```
## Destroy
The following command forces to stop a specific domain simulating a power button press:
```
snow destroy <domain>
```
## Power Off
The following command initiates a soft-shutdown of the OS via ACPI for domain:
```
snow poweroff <domain|node>
```

{% include callout.html content="Differences between shutdown, destroy and poweroff: <br>**shutdown** requires access to the OS in order to be able to trigger 'systemctl poweroff' command. <br>**destroy** forces to stop specific domain or node simulating a power button press. This is performed at the API level in those situations where the system is up but is not responsive (i.e. a boot failure).<br>**poweroff** initiates a soft-shutdown of the OS via ACPI. This is useful when for some reason you don't have access through SSH but you have access from console (i.e. the system booted without network configuration)." type="success" %}
