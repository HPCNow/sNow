---
title: Hardware Requirements
sidebar: mydoc_sidebar
permalink: mydoc_intro_hardware_requirements.html
folder: mydoc
---


1. An internal network switch with enough ports available
* 1 port per node, minimum, for ethernet provisioning
* 2 ports per node if you want to use a dedicated IPMI port

2. Low latency and high bandwidth network switch (optional)
Depending on your workload and especially if you run MPI applications or you need very fast access to a shared disk, it is recommended to use a high speed network. You can choose any of the existing technologies such as Infiniband, OmniPath, or 10GbE.

3. One sNow! server with :
* At least 24 GB of RAM
* 12 cores or 24 with hyper-threading active (recommended)
* 1 TB HDD (hardware Raid 1 recommended)
* 2 NICs Gigabit ethernet (4 NICs with bonding recommended)
* Redundant power supply recommended.
* You must have internet access in order to install sNow!.
