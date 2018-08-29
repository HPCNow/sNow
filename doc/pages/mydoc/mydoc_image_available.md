---
title: Image Available
tags: [image, diskless]
keywords: image management, cloning, clone, image, diskless, stateless, nfsroot
last_updated: July 3, 2016
summary: "sNow! allows to import existing OS images from a shared registry. You can list the available images from HPCNow! registry of from third party company."
sidebar: mydoc_sidebar
permalink: mydoc_image_available.html
folder: mydoc
---
## HPCNow! registry
HPCNow! maintains a registry of tuned OS images for HPC, Big Data, Artificial Intelligence and Machine Learning. You can list those images by using the following command line:
```
snow image avail
```
If you are looking for an specific image name, you can use the ```--search="<string>"``` to search by a string.
Example:
```
snow image avail --search=centos
```
## Use an external registry
You can search on external registry by using the option ```--registry=<url>```. Example:
```
snow image avail --registry=http://registry.hpcnow.com --search=centos
```
