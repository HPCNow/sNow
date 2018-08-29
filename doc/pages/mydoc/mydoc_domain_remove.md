---
title: Domains Remove
keywords: deployment, domains
last_updated: March 20, 2016
summary: "This section explains how to remove a previously deployed sNow! domain."
sidebar: mydoc_sidebar
permalink: mydoc_domain_remove.html
folder: mydoc
---

In order to remove an existing domain, use the following command:
```
snow remove domain <domain_name>
```
{% include warning.html content="Be careful with this action. The domain can not be recovered once is removed unless you recover it from a backup. You will able to recover the service by re-deploying the domain but logs and databases may be lost." %}

Example:
```
snow remove domain slurmdbd01
```
