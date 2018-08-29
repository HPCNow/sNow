---
title: Compute Node Remove
keywords: deployment, Compute Node
last_updated: March 20, 2016
summary: "This section explains how to remove a previously deployed sNow! Compute Node."
sidebar: mydoc_sidebar
permalink: mydoc_node_remove.html
folder: mydoc
---

In order to remove an existing compute node or a range of compute nodes, use the following command:
```
snow remove node <compute_node_name(s)>
```
{% include warning.html content="Be careful with this action. The compute can not be recovered once is removed unless you recover it from a backup. You will able to recover the service by re-deploying the domain but logs and databases may be lost." %}

Example:
```
snow remove nodes node-[001-010]
```
