# README #

sNow! Tools includes the CLI, templates and profiles for interacting with sNow! Cluster Manager.

### Overview ### 

sNow! is an OpenSource HPC suite which provides all the required elements to deploy, manage and customize a compute solution. With the sNow! default configuration you will able to setup a completely functional HPC cluster from scratch in very short time.

The predefined configuration contains advanced features which significantly reduce additional complexities for the end user. In addition to that, sNow! allows to integrate simple hook scripts to customize your system in order to meet your needs.

We believe that HPC facilities will take advantage of this work and they will be able to deliver all this material to their end users after applying minor changes in the configuration and also in the documentation.

### Quick Install Notes ###
1. This starts by installing Debian on your sNow! server, typically named snow01. This server will have at least two network ports, one to connect to the internal sNow network (192.168.7.0 in this document) and one to connect to your house network, which will be used for the users to be able to interact with the computing cluster.

1. Extend the repos with contrib and non-free 

1. Install pre-required software

```
apt-get install bridge-utils gawk lvm2 sudo wget git
```

1. Execute the following commands to start the sNow! installation

```
git clone https://bitbucket.org/hpcnow/snow-tools.git 1.1.0 
cd snow-tools
./install.sh
```

### sNow! Configuration ###

Follow the sNow! Administration Guide

