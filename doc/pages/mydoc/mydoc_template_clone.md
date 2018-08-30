---
title: Template Clone
tags: [template deployment cloning]
keywords: template, deployment, cloning
last_updated: July 3, 2016
summary: "This section explains how to create a new template based on an existing template (clone)."
sidebar: mydoc_sidebar
permalink: mydoc_template_clone.html
folder: mydoc
---

In order to create a new template from an existing one, you can use the following command:
```
snow clone template <template_name> <new_template_name> <description>
```
The following example will create a new CentOS template (```centos-7.3-custom```) based on the default CentOS template (```centos-7-default```):
```
snow clone template centos-7.3-default centos-7.3-custom "This template contains my custom hooks and configuration"
```
You can also list all the available deployment templates with the following command:
```
# snow list templates
Template Name                     Description
-------------                     -----------
centos-7.3-default                Default template based on CentOS 7.3
                                  path : ${SNOW_SRV}/templates/centos-7.3-default
centos-7.3-custom                 This template contains my custom hooks and configuration
                                  path : ${SNOW_SRV}/templates/centos-7.3-custom
```
{% include note.html content="You can also use ```centos-7.3-custom``` as your default deployment template by changing the ```DEFAULT_TEMPLATE``` value in snow.conf." %}
