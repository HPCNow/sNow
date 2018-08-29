---
title: Domains Deployment
keywords: deployment, domains
last_updated: March 20, 2016
summary: "This section explains how to deploy and boot sNow! domains"
sidebar: mydoc_sidebar
permalink: mydoc_domain_deploy.html
folder: mydoc
---

Some domains have internal dependencies with others. At the time of writing, sNow! is not able to resolve these dependencies, but it will in a future release. The following commands are ordered in such a way that it can resolve the dependencies.

Each domain usually takes between one and two minutes to be deployed and booted, although this will depend on your system's performance. The aim is to be able to deploy the compute nodes and cluster infrastructure within 1-2 hours.

If you want to see what is happening during the deployment process, you can open a new shell and review the output of the log file in real time, using the following command (this is also valid during any interaction with the snow command):
```
tail -f /sNow/log/snow.log
```
In order to deploy the default domains, run the following commands:
```
snow deploy deploy01
snow deploy ldap01
snow deploy syslog01
snow deploy proxy01
snow deploy slurmdb01
snow deploy slurm01
snow deploy monitor01
snow deploy login01
```
