---
title: SSH access with sNow! user or HPCNow! user
permalink: mydoc_install_ssh_access.html
keywords: ssh access
sidebar: mydoc_sidebar
folder: mydoc
---

During the installation process one or two users have been created:
* The sNow! user (snow) is the admin user which will be able to install scientific applications and to escalate to root privileges.  
* [optional] The HPCNow! user (hpcnow) can also escalate to root privileges and is meant to be used for remote administration and support.
{% include note.html content="By default, the only way to access the system as the sNow! or HPCNow! user is by using the SSH key located in the user’s home directory. Note that at this point, those users do not have a password. If you want to enable password access, you will need to setup a password first." %}
## Access as sNow! user with the SSH key
You will need to transfer a copy of the snow user SSH key to your desktop computer. You can copy this file to a pendrive or transfer the file from the sNow! server through SCP or any other file transfer mechanism.
## Allow access for professional remote administration and support
You will need to provide the HPCNow! user name and the SSH key or password to the remote administration engineer.
