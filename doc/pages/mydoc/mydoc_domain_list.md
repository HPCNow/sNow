---
title: Domains List
keywords: list, domains
last_updated: March 20, 2016
summary: "This section explains how to list the domains already configured in sNow!"
sidebar: mydoc_sidebar
permalink: mydoc_domain_list.html
folder: mydoc
---
In order to check the status of the domains and other key information, execute the following command:
```
snow list domains
```
This list provides detailed information about each domain, including:
* Name of the domain
* Status of the virtual machine/container
* Status of the OS
* The roles associated to the domain_name
* The host where the domain is running

Example:
```
snow list domains
Domain                HW status   OS status                                 Roles                Host
------                ---------   ---------                                 -----                ----
proxy01               on          up 2 weeks, 20 hours, 21 minutes          proxy                snow01
proxy02               on          up 2 weeks, 20 hours, 21 minutes          proxy                snow02
monitor01             on          up 2 weeks, 20 hours, 21 minutes          monitor              snow01
monitor02             on          up 2 weeks, 20 hours, 21 minutes          monitor              snow02
ldap01                on          up 2 weeks, 20 hours, 21 minutes          ldap-master          snow01
ldap02                on          up 2 weeks, 20 hours, 21 minutes          ldap-replica         snow02
syslog01              on          up 2 weeks, 20 hours, 21 minutes          syslog               snow02
maui01                on          up 2 weeks, 20 hours, 21 minutes          torque-master        snow01
deploy01              on          up 2 weeks, 20 hours, 21 minutes          deploy               snow01
deploy02              on          up 2 weeks, 20 hours, 21 minutes          deploy               snow02
login01               on          up 2 weeks, 20 hours, 21 minutes          login,cfs            snow01
login02               on          up 2 weeks, 20 hours, 21 minutes          login,cfs            snow02
```
