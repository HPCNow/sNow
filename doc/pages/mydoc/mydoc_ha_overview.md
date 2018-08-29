---
title: Scalability and High Availability Overview
summary: "This section provides an overview of different strategies to achieve scalability and high availability"
sidebar: mydoc_sidebar
permalink: mydoc_ha_overview.html
folder: mydoc
---

sNow! supports multiple levels of high availability (HA). Most of the HA services based on load balancing (LB) are key to achieving not only resilience and scalability.

The easiest and preferred way to setup domains in HA mode is by taking advantage of the already implemented native HA support for those services allocated in each domain. On top of this HA layer, you can setup additional HA at the virtualization level by using standard software packages like corosync and pacemaker.

The following sections explain in detail how to setup different HA implementations. The suitability of those implementations will depend on your needs and expectations.
