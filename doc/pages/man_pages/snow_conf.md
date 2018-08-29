---
title: snow.conf Man Page
keywords: sample
summary: "This is just a sample topic..."
sidebar: man_pages_sidebar
permalink: snow_conf.html
simple_map: true
map_name: usermap
box_number: 1
folder: man_pages
---
# snow.conf man page
The snow command is the most important administration command you will use to manage your cluster. It allows you to do the initial configuration, deploy the domains and compute nodes, boot or power cycle them when needed, open the console, PXE install the compute nodes, etc. This command interacts with the cluster in two ways:
When focused on a domain or VM, it is a wrapper which runs the appropriate XEN commands to control the domain.
When focused on compute nodes it uses the IPMI interface to control the compute nodes.

The following sections will explain in detail how to interact with the snow command.

```
snow [function] <domain|node> <option>
```

## Man pages
There is a manpage covering the usage of the snow command. We encourage you to read it as it might have information not available in this guide or, at least, organized in a different way. The available man pages are :
* snow
* snow.conf
* active-domains.conf
* domains.conf

## Version and help
### version
shows the version of sNow!
### help
prints the standard help message

## Power up/down/cycle
### boot <domain>
boots a specific domain
### boot <node>  <image> 
boots specific node(s) with an optional image
### boot domains
boot all domains (all services not available under sNow! HA)
### boot cluster <clustername>
boot all the compute nodes of the selected cluster (by default 12 nodes at once)
### reboot <domain|node>
reboot a specific domain or node(s)
### shutdown <domain|node>
shutdown a specific domain or node(s)
### shutdown cluster <clustername>
shutdown all the compute nodes of the selected cluster
### destroy <domain|node>
force stop a specific domain or node(s) simulating a power button press
### reset <domain|node>
force rebooting a specific domain or node(s)
### poweroff <domain|node>
initiate a soft-shutdown of the OS via ACPI for domain(s) or node(s)

## Provisioning
### deploy <domain|node> <template> <force>
deploy a specific domain/node (optional: with specific template or force deploying existing domain/server)
### add node <node> [--option value]
adds a new node in the sNow! database. Available options: cluster, image, template, install_repo, console_options
### set node <node> [--option value]
sets parameters in the node description. Available options: cluster, image, template, install_repo, console_options
### clone template <old> <new> <description>
creates a new template based on an existing one
### clone image <old> <new> <description>
creates a new image based on an existing one
### clone node <node> <image> <type>
creates an image to boot the compute nodes diskless. Available types (nfsroot, stateless).
### remove domain <domain>
removes an existing domain deployed with sNow!
### remove node <node>
removes an existing node from sNow! configuration
### remove template <template>
removes an existing template
### remove image <image>
removes an existing image
### list domains
list the current domains (services) and their status
### list templates
list the templates installed in the system
### list nodes
list the available compute nodes and their status
### list roles
list the available roles for domains (services)
### list images
list the images generated or downloaded
### show nodes <node>
shows the node(s) configuration.

## Console
### console <domain|node>
console access to specific domain or node
* Use ENTER followed by ```~.``` to exit an IPMI (compute node) console.
* Use ```<CTRL> ]``` to exit a XEN (VM) console.

NOTE: The SSH sessions capture the ```~``` char, so if you are in a situation like:

```
ssh snow01
snow console n001
```
To exit the console you will need an additional ~ for each SSH session. In this case:
```~~.```


## Update sNow!
### update tools
updates the sNow! Tools
## update configspace
updates configuration files from the private Git repository
### update template
updates the sNow! image used to create new domains

## Configuration
### init
initiates the system configuration according to the parameters defined in snow.conf and active-domains.conf
### config
dumps the information available in snow.conf and domains.conf. Use it to keep track of changes.
### update firewall
updates the default sNow! firewall rules (only for sNow! with public IP address and internal DMZ)
### chroot <image>
provides chroot environment inside a read-only nfsroot image. The prompt provided by this command also shows that the shell session is allocated inside a particular image chroot. In order to exit from this environment, type exit or press ```Ctrl+d```.

{% include links.html %}
