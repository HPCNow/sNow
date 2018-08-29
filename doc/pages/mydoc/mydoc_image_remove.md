---
title: Image Remove
tags: [image, diskless]
keywords: image management, cloning, clone, image, diskless, stateless, nfsroot
last_updated: July 3, 2016
summary: "This section explains how to remove an image"
sidebar: mydoc_sidebar
permalink: mydoc_image_remove.html
folder: mydoc
---

In order to remove an existing image, use the following command:
```
snow remove image <image_name>
```
{% include warning.html content="Be careful with this action. The image can not be recovered once is removed unless you recover it from a backup." %}

Example:
```
snow remove image centos-7.3-custom
```
