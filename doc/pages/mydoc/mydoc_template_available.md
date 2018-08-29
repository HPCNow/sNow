---
title: Template List
tags: [template deployment cloning]
keywords: template, deployment, cloning
last_updated: July 3, 2016
summary: ""
sidebar: mydoc_sidebar
permalink: mydoc_template_available.html
folder: mydoc
---

If you want to clone the default centos-7-default template you will need to do the following:

```
snow clone template centos-7.3-default centos-7.3-custom "This template contains my custom hooks and configuration"
```
Then you can deploy the cloned template by:

```
snow deploy <nodelist> centos-7-custom
```
You can also use ```centos-7.3-custom``` as your default deployment template by changing the ```DEFAULT_TEMPLATE``` value in snow.conf.

You can also list all the available deployment templates with the following command:

```
# snow list templates
Template Name                     Description
-------------                     -----------
centos-7.3-default                Default template based on CentOS 7.3
                                  path : /sNow/snow-configspace/boot/templates/centos-7.3-default
centos-7.3-custom                 This template contains my custom hooks and configuration
                                  path : /sNow/snow-configspace/boot/templates/centos-7.3-custom
```
