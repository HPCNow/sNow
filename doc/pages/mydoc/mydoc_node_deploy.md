---
title: Deploy the first compute node
keywords: deploy, compute node
last_updated: July 3, 2016
tags: [deploy]
summary: "This section explains how to deploy a compute node using an existing template"
sidebar: mydoc_sidebar
permalink: mydoc_node_deploy.html
folder: mydoc
---
## Deploy a Compute Node with Default Template
The parameter ```DEFAULT_TEMPLATE``` defines the global default template to deploy compute nodes. If the node does not have a pre-defined template, it will use the global default version. The default template for a particular node can be defined by using the ```snow set node --template <template_name>```. More information about how to setup per node basis templates available [here](mydoc_node_set.html).
```
snow deploy <compute_node(s)>
```
## Deploy a Compute Node with a Specific Template
In order to deploy a compute node using a specific template, use the following command:
```
snow deploy <compute_node(s)> <template_name>
```
More information about that available in [Template Overview](mydoc_template_overview.html)
