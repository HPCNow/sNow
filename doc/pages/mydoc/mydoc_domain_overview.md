---
title: Domains Overview
keywords: deployment, domains
last_updated: March 20, 2016
summary: "This section provides an overview of sNow! domains"
sidebar: mydoc_sidebar
permalink: mydoc_domain_overview.html
folder: mydoc
---

On traditional HPC systems, all the services required to manage the cluster are usually allocated in the head node. This node becomes a single point of failure and the performance of that node, and also of the cluster, depends on the load of those services. A misbehaving service could affect the performance and the responsiveness of the cluster (i.e. a new user performing a CPU intensive task or a DOS attack in the SSH or web services).

sNow! provides all the critical services segmented in a virtualization layer, giving flexibility and scalability to meet customer needs. This structure also allows to control and isolate services avoid instability introduced by a particular service.

{% include note.html content="sNow! currently supports Xen Source and Linux Containers (experimental) virtualization technologies. In sNow! argot, those virtual environments are known as *domains*." %}

## Key Features

### Painless Services Deployment
sNow! domains are unattended deployed by pre-defined roles. Those roles, are shell scripts which make them easy to develop and to understand. More information about roles available in the [Role Overview](mydoc_role_overview) section.

### Easy to Integrate to Your Site Needs
sNow! domains allow integrating a consolidated IT environment without the overhead. The hook rich architecture allows integrating uncommon needs easily and/or develop your own roles to deploy custom domains.

### Mission Critical Focused
The sNow! architecture has been designed to leverage services for mission critical HPC environment, where downtime is not an option. sNow! allows one to perform critical migrations without stopping the system or its services as all services can be live-migrated to any other sNow! servers.

Complex and critical actions like updating the workload manager or upgrading the firmware on the nodes do not longer require a downtime, but a progressive upgrade process that can be completed in a matter of hours or weeks.

### DevOps Friendly
sNoW! domains are key to develop a real DevOps friendly solution, easy to interact, develop, rebuild and also accommodate Continuous Integration needs.

### Community Driven
sNow! is not only Open Source, it's community driven. Your feedback, suggestions, and requirements have an impact on the development and in the roadmap of the project. This also opens opportunities to share and contribute back to the community.
