---
title: sNow! Command Line Interface Administratrion
tags: [special_layouts]
keywords: CLI
last_updated: July 3, 2016
summary: "Quick summary of sNow! CLI"
sidebar: mydoc_sidebar
permalink: mydoc_admin_snow_cli.html
folder: mydoc
---

The snow command is the most important administration command you will use to manage your cluster. It allows you to do the initial configuration, deploy the domains and compute nodes, boot or power cycle them when needed, open the console, PXE install the compute nodes, etc. This command interacts with the cluster in two ways:
When focused on a domain or VM, it is a wrapper which runs the appropriate XEN commands to control the domain.
When focused on compute nodes it uses the IPMI interface to control the compute nodes.

The following sections will explain in detail how to interact with the snow command.
```
snow [function] <domain|node> <option>
```
## Man pages
There is a manpage covering the usage of the snow command. We encourage you to read it as it might have information not available in this guide or, at least, organised in a different way. The available man pages are :
* snow
* snow.conf
* active-domains.conf
* domains.conf

## Version and help

* ```version``` shows the version of sNow!

* ```help``` prints the standard help message


## Power up/down/cycle

* ```boot <domain>``` boots a specific domain

* ```boot <node> <image>``` boots specific node(s) with an optional image

* ```boot domains``` boots all domains (all services not available under sNow! HA)

* ```boot cluster <clustername>``` boots all the compute nodes of the selected cluster (by default 12 nodes at once)

* ```reboot <domain|node>``` reboots a specific domain or node(s)

* ```reset <domain|node>``` force rebooting a specific domain or node(s)

* ```shutdown <domain|node>``` shutdown a specific domain or node(s)

* ```shutdown cluster <clustername>``` shutdown all the compute nodes of the selected cluster

* ```destroy <domain|node>``` force stop a specific domain or node(s) simulating a power button press

* ```poweroff <domain|node>``` initiate a soft-shutdown of the OS via ACPI for domain(s) or node(s)

{% include callout.html content="Differences between shutdown, destroy and poweroff: <br>**shutdown** requires access to the OS in order to be able to trigger 'systemctl poweroff' command. <br>**destroy** forces to stop specific domain or node simulating a power button press. This is performed at the IPMI or API level in those situations where the system is up but is not responsive (i.e. a boot failure in PXE).<br>**poweroff** initiates a soft-shutdown of the OS via ACPI. This is useful when for some reason you don't have access through SSH but you have access from console (i.e. the system booted without network configuration)." type="success" %}

## Provisioning
* ```deploy <domain|node> <template> <force>``` deploy a specific domain/node (optional: with specific template or force deploying existing domain/server)

* ```add node <node> [--option value]``` adds a new node in the sNow! database. Available options: cluster, image, template, install_repo, console_options

* ```set node <node> [--option value]``` sets parameters in the node description. Available options: cluster, image, template, install_repo, console_options

* ```clone template <old> <new> <description>``` creates a new template based on an existing one

* ```clone image <old> <new> <description>``` creates a new image based on an existing one

* ```clone node <node> <image> <type>``` creates an image to boot the compute nodes diskless. Available types (nfsroot, stateless).

* ```remove domain <domain>``` removes an existing domain deployed with sNow!

* ```remove node <node>``` removes an existing node from sNow! configuration

* ```remove template <template>``` removes an existing template

* ```remove image <image>``` removes an existing image

* ```list domains``` list the current domains (services) and their status

* ```list templates``` list the templates installed in the system

* ```list nodes``` list the available compute nodes and their status

* ```list roles``` list the available roles for domains (services)

* ```list images``` list the images generated or downloaded

* ```show nodes <node>``` shows the node(s) configuration.

## Console
* ```console <domain|node>``` console access to specific domain or node
  * Use ENTER followed by ```~.``` to exit an IPMI (compute node) console.
  * Use <CTRL> ] to exit a XEN (VM) console.

{% include tip.html content="When connected to an IMPI console, each SSH session captures one ~ char. In order to escape from the console session with one ssh server in between, type ```~~.```" %}

## Update sNow!
* ```update tools``` updates the sNow! Tools

* ```update configspace``` updates configuration files from the private Git repository

* ```update template``` updates the sNow! image used to create new domains

## Configuration
* ```init``` initiates the system configuration according to the parameters defined in snow.conf and active-domains.conf

* ```config``` dumps the information available in snow.conf and domains.conf. Use it to keep track of changes.

* ```update firewall``` updates the default sNow! firewall rules (only for sNow! with public IP address and internal DMZ)

* ```chroot <image>``` provides chroot environment inside a read-only nfsroot image. The prompt provided by this command also shows that the shell session is allocated inside a particular image chroot. In order to exit from this environment, type exit or press Ctrl+d.
