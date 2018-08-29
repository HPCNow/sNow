---
title: Image Gather
tags: [image, diskless]
keywords: image management, cloning, clone, image, diskless, stateless, nfsroot
last_updated: July 3, 2016
summary: "This section provides detailed information about image gathering."
sidebar: mydoc_sidebar
permalink: mydoc_image_gather.html
folder: mydoc
---
## Create a Compute Node OS Image
In order to generate an image a previously deployed system is required. The following command creates a diskless image.
```
snow clone node <node> <image> <nfsroot|stateless>
```
{% include warning.html content="Please remember that Stateless image is not yet suitable for production in the current release, unless you have support." %}

### Single System Image gathering example
```
snow clone node hsw01 centos-minimal nfsroot
```

### Stateless image gathering example
```
snow clone node hsw01 centos-minimal stateless
```
