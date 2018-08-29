---
title: Template Remove
tags: [template deployment remove]
keywords: template, deployment, cloning
last_updated: July 3, 2016
summary: "This section explains how to remove a template."
sidebar: mydoc_sidebar
permalink: mydoc_template_remove.html
folder: mydoc
---

In order to remove an existing template, use the following command:
```
snow remove template <template_name>
```
{% include warning.html content="Be careful with this action. The template can not be recovered once is removed unless you recover it from a backup." %}

Example:
```
snow remove template centos-7.3-custom
```
