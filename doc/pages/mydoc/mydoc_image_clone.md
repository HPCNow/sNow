---
title: Image Management
tags: [image, diskless]
keywords: image management, cloning, clone, image, diskless, stateless, nfsroot
last_updated: July 3, 2016
summary: "This section provides information about how to generate a compute node OS image."
sidebar: mydoc_sidebar
permalink: mydoc_image_clone.html
folder: mydoc
---

## Image cloning
If you want to apply major changes in the image, its usually a good idea to clone the image before doing so. This way, you can always roll back to the previous configuration. The following command allows creating a new image as a copy of an existing one:
```
snow clone image <image> <new_image>
```
Example:
```
snow clone image centos-minimal centos-custom
```
