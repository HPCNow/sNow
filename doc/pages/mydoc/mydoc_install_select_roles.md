---
title: Select Domains Roles
tags: [domain, role, vm, container]
keywords: domain, role, vm, container
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_install_select_roles.html
folder: mydoc
---
{% include note.html content="In this documentation we are referring to the independent systems running different sNow services as 'domains' or 'virtual machines' or 'containers'." %}

Each domain has one or more roles. Each role defines a service or a subset of related services. The roles are scripts which automate the process of deploying a new domain and also configure them based on the parameters available in the main sNow! configuration file (snow.conf).

The ```active-domains.conf``` file provides a list of sNow! domains and the associated roles which define the services provided by each domain. You can modify this list at your convenience.

The first column of the ```active-domains.conf``` file contains the hostname of the domain, the second column contains the role or list or roles associated with the domain. Each domain can have one or more roles. In the case of multiple roles, use a comma separated list with no spaces.

The following command line, provides a short description for each role available in ```/sNow/snow-tools/etc/roles.d```.
```
snow list roles
```
The file ```/sNow/snow-tools/etc/active-domains.conf-example``` contains the most popular roles used in general HPC clusters. To enable those roles, copy the example file as your working file:
```
cp -p /sNow/snow-tools/etc/active-domains.conf-example /sNow/snow-tools/etc/active-domains.conf
```
* For more information about sNow! domain roles, visit the [Role Management - Overview](mydoc_role_overview.html) section.
* For more information about the available roles, visit the [Role Management - Available Roles](mydoc_role_available.html) section.
* For more information about how to develop a custom role, visit the [Role Management - Custom Roles](mydoc_role_custom.html) section.
