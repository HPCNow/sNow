---
title: Image Modify
tags: [image, diskless]
keywords: image management, cloning, clone, image, diskless, stateless, nfsroot
last_updated: July 3, 2016
summary: "This section provides information about how to perform some modifications in a particular system image."
sidebar: mydoc_sidebar
permalink: mydoc_image_modify.html
folder: mydoc
---

## Customise your image with hooks
If you want to perform an action every time the node is booted, you can take advantage of the first boot hooks. Those hooks are standard shell scripts located inside the first_boot folder. The name schema is exactly the same as that of the regular hooks described in the section 6 (link) and must be owned by root and be executable.
```
first_boot/??-hook-name.sh
```

## Update your image online [Single System Image only]
Sometimes there are some changes that doesn’t require a reboot of the system or an outage to apply changes. In the case where a read-only nfsroot image system is used, you will be able to apply some changes online easily.
From one of the sNow! servers, where you have “read and write” access to the image, you can modify the file system (edit, copy, remove, etc) and the changes are going to be instantly available cluster wide.
When you list the images available in your system, you also get the path where each image is located. The folder rootfs inside this path contains all the files of the OS image. Following on from the previous example, the files of the centos-minimal OS image are located in the folder:
```
$ ls -l ${SNOW_SRV}/images/centos-minimal/rootfs
total 64
lrwxrwxrwx   1 root root    7 abr  3 10:43 bin -> usr/bin
dr-xr-xr-x+  5 root root 4096 abr  3 11:15 boot
drwxr-xr-x+  2 root root 4096 abr  3 10:57 dev
drwxr-xr-x+ 88 root root 4096 abr  5 22:10 etc
drwxr-xr-x+  5 root root 4096 nov  3 10:09 home
lrwxrwxrwx   1 root root    7 abr  3 10:43 lib -> usr/lib
lrwxrwxrwx   1 root root    9 abr  3 10:43 lib64 -> usr/lib64
drwxr-xr-x+  2 root root 4096 nov  5 16:38 media
drwxr-xr-x+  2 root root 4096 nov  5 16:38 mnt
drwxr-xr-x+  2 root root 4096 nov  5 16:38 opt
dr-xr-xr-x+  2 root root 4096 abr  3 10:57 proc
dr-xr-x---+  3 root root 4096 abr  3 23:23 root
drwxr-xr-x+ 24 root root 4096 abr  3 11:15 run
lrwxrwxrwx   1 root root    8 abr  3 10:43 sbin -> usr/sbin
drwxr-xr-x+  2 snow snow 4096 abr  2 23:26 sNow
drwxr-xr-x+  2 root root 4096 nov  5 16:38 srv
dr-xr-xr-x+  2 root root 4096 abr  3 10:57 sys
drwxrwxrwt+  7 root root 4096 abr  6 03:07 tmp
drwxr-xr-x+ 13 root root 4096 abr  3 10:43 usr
drwxr-xr-x+ 18 root root 4096 abr  5 22:10 var
```

Also, you could do more advanced operations like installing a new package or interacting with some program which usually requires human interaction. In order to do so, you can take advantage of the following command to get instant access to a chroot environment inside the image system.
```
snow chroot <image_name>
```
The prompt provided by this command also highlights that this session is allocated inside a particular image chroot.
In order to exit from this environment, type exit or press Ctrl+d.
## Example: Install a new package
```
[root] snow01:~ # snow chroot centos-minimal
[ centos-minimal ] # yum install htop -y
```
