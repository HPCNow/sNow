---
title: Escalate to root user
keywords: root access escalate
sidebar: mydoc_sidebar
permalink: mydoc_install_escalate_to_root.html
folder: mydoc
---

{% include note.html content="The root user and sNow! user are able to access, as a root, all domains and servers managed by sNow! but only from the sNow! servers. This means that you will be not able to escalate to root privileges from the login node, a compute node or any domain." %}

Access as sNow! user and execute the following command line:
```
sudo su -
```
