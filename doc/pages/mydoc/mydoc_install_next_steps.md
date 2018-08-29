---
title: Next Steps
permalink: mydoc_install_next_steps.html
keywords: next steps
summary: "This section explains the next steps required to complete your cluster installation."
sidebar: mydoc_sidebar
folder: mydoc
---

The following steps will guide you to setup the cluster and the services as you need.

## Domains Deployment
Each domain usually takes between one and two minutes to be deployed and booted, although this will mostly depend on your system's IO performance. Follow the instructions detailed in the [domain deploy](mydoc_domain_deploy.html) section.
## Hardware Stress on Compute Nodes
sNow! installs by default a small OS image which allows to stress the compute nodes to detect potential hardware issues early.
Consider to run those tests while you are deploying the first node or customising the deployment templates. This image can also be used to generate the mac addresses database (see next section).
```
snow boot node[001-999] stress-x64
```
## Mac Addresses Gathering
Collecting the MAC addresses in a cluster is simple but can be time consuming. This [section](mydoc_node_how_to_collect_the_mac_addresses.html) explains some tricks to avoid spending too much time doing this.
## Compute Node Deployment
sNow! supports multiple Linux distributions for the deployment for compute nodes. You can list all of the available templates with the following command:
```
snow list templates
```
When setting up a cluster there are actions which only need to be performed once per cluster. In order to do so, sNow! defines a especial role called *golden node* where these actions are to be performed on. In the case of very heterogeneous architectures allocated in the same cluster, these actions may need to be performed once per architecture.

If you want to deploy a compute node based on a pre-defined template. You can use the following command (i.e.)
```
snow deploy <first_compute_node> <name_of_the_template>
```
Example:
```
snow deploy n001 centos-7.4-default
```
If you wish provisioning the cluster by deploying, replace the n001 with the cluster name or the node range to be deployed.
HPCNow! strongly recommends considering diskless image provisioning to accelerate the provisioning of large clusters. The next two steps detail the process of image gathering and cluster image provisioning.
## Compute Node Image Gathering
In order to generate the first image, a previously deployed system is required. sNow! supports different types of image based provisioning. Consider to explore the [image type](mydoc_image_types.html) section to learn more about that.

The following example instructs sNow! to gather a stateless image:
```
snow clone node n001 centos-7.4-minimal stateless
```
## Compute Node Image Provisioning
Finally, for provisioning the cluster using diskless image you only need to execute the following command:
```
snow boot <cluster_name> <image_name>
```
Example:
```
snow boot mycluster centos-7.4-minimal
```
