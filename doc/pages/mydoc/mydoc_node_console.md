---
title: Node Console
keywords: console, compute node
last_updated: March 20, 2016
summary: "This section explains how to access to a compute node console."
sidebar: mydoc_sidebar
permalink: mydoc_node_console.html
folder: mydoc
---

## Get Console Access
In order to get access to any of the compute nodes' console, execute the following command:
```
snow console <domain_name>
```
## Exit from Console
In order exit from a console session, use ```<CTRL> ]```.

{% include tip.html content="When connected to an IMPI console, each SSH session captures one ~ char. In order to escape from the console session with one ssh server in between, type ```~~.```" %}
