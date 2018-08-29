---
title:  Hostname Setting
tags: [content_types]
keywords: groups, api, structure
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_install_hostname_setting.html
folder: mydoc
---

The sNow! server hostname must match with the IP of the snow network bridge (xsnow01).
Review your ```/etc/hosts``` file and check that it is correct.

Example:

```
127.0.0.1       localhost
YOUR_LAN_IP     snow01-pub.hpcnow.com        snow01-pub
192.168.7.1     snow01
```
