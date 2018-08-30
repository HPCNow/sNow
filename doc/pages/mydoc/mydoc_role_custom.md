---
title: Custom Roles
summary: "This section explains how to develop new custom sNow! domain roles."
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_role_custom.html
folder: mydoc
---

## Create a New Custom Role
sNow! domain roles are shell scripts which make them easy to develop and to understand. Keep in mind the following tips and tricks which will help you  develop new roles:

* Use environment variables defined in snow.conf, and extend them if you need new variables to work with
* When you generate a new configuration file, remember to copy the file in the deployed system and also ```${SNOW_SRV}/deploy_files```. If there is a file in this path, avoid overwriting it and use it to setup your new system. This will help you to setup continuous integration into your system.
* Place comments inside complex sections of the code in order to help people to understand what you are doing
* Use chroot ${prefix} to run commands inside the new deployed system
* Use installDebianPackage ${prefix} to install packages
* Use variables inside the templates that easy to recognise and replace ```__NAME_OF_VARIABLE__```
* Use sed with pipe symbols rather than slash symbols. This will help you to replace UNIX paths.
* In this directory (```${SNOW_SRV}/deploy_files```) you will find the configuration files used in the different roles. Some of them are common for many roles. Some of them are common to all of them. This is a list of files used for the preinstalled roles.

The role template ```snow_reference_template``` will help you to develop new roles (available in ${SNOW_ETC}/role.d/snow_reference_template).
Consider to share the new role upstream following the instructions detailed [here](mydoc_contribute_back.html)
``` bash
#!/bin/bash
# Configure the new image for sNow! HPC suite
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
#SHORT_DESCRIPTION: Template to help sNow! users to develop their own roles quickly.

# Now! roles are shell scripts easy to develop and to understand
# Keep in mind the following tips and tricks which will help you to develop new roles:
# (1) Use environment variables defined in snow.conf, and extend them if you need new
#     variables to work with
# (2) When you generate a new configuration file, remember to copy the file in the
#     deployed system and also ${SNOW_SRV}/deploy_files. If there is a file
#     in this path, avoid to overwrite it and used it to setup your new system. i
#     This will help to integrate Continuous Integration into your system.
# (3) Place comments inside complex sections of the code in order to help people to understand what you are doing
# (4) Use chroot ${prefix} to run commands inside the new deployed system
# (5) Use installDebianPackage ${prefix} to install packages
# (6) Use variables inside the templates easy to recognise and replace __NAME_OF_VARIABLE__
# (7) Use sed with pipe symbols rather than slash symbols. This will help you to replace unix path.

prefix=$1

#  Source our common functions - this will let us install a Debian package.
if [[ -e /usr/share/xen-tools/common.sh ]]; then
    source /usr/share/xen-tools/common.sh
else
    echo "Installation problem"
fi
# Load sNow! configuration
if [[ -e ${SNOW_ETC}/snow.conf ]]; then
    declare -A CLUSTERS
    source ${SNOW_ETC}/snow.conf
else
    error_msg  "The ${SNOW_ETC}/snow.conf is not available."
    error_exit "Please use the ${SNOW_ETC}/snow.conf-example to setup your environment."
fi
# Load sNow! functions
if [[ -f ${SNOW_ROOT}/share/common.sh ]]; then
    source ${SNOW_ROOT}/share/common.sh
    get_os_distro
    architecture_identification
fi

##############     EVALUATE WHO PROVIDES THE SERVICE (SITE, SNOW or BOTH)     ###############
# Setup New Service Client
# get the IP of the server offering this service
SNOW_NEWSERVICE_SERVER=$(gawk '{if($2 ~ /service/){print $4}}' $SNOW_ROOT/etc/domains.conf)
# If the site is offering the server already and sNow! is also deploying the server,
# then we assume that sNow server will act as a proxy or relay server (useful to avoid DOS of performance degradation)
# Otherwise, we will use the only available service.
if  [[ ! -z "$SNOW_NEWSERVICE_SERVER" && ! -z "$SITE_NEWSERVICE_SERVER" ]]; then
    NEWSERVICE_SERVER=$SNOW_NEWSERVICE_SERVER
else
    NEWSERVICE_SERVER="${SITE_NEWSERVICE_SERVER:-$SNOW_NEWSERVICE_SERVER}"
fi

##############     EVALUATE IF THE SERVER IS AVAILABLE/EXPECTED OR NOT     ###############
if  [[ ! -z "$NEWSERVICE_SERVER" ]]; then
    # Install the required packages
    installDebianPackage ${prefix} whatever
    # Check if the configuration file already exists
    if [[ -e ${SNOW_SRV}/deploy_files/etc/NEWSERVICE.conf ]]; then
        # Transfer the existing file to the final destination
        cp -p ${SNOW_SRV}/deploy_files/etc/NEWSERVICE.conf ${prefix}/etc/NEWSERVICE.conf
    else
        # Parse the default configuration file provided by the OS distribution or your advanced
        # configuration template located in etc/config_template.d/NEWSERVICE/NEWSERVICE.conf
        # cp -p etc/config_template.d/NEWSERVICE/NEWSERVICE.conf ${prefix}/etc/NEWSERVICE.conf
        sed -i 's|__NEW_SERVICE_PARAMETER__|$NEW_SERVICE_PARAMETER|g' ${prefix}/etc/NEWSERVICE.conf
        cp -p ${prefix}/etc/NEWSERVICE.conf ${SNOW_SRV}/deploy_files/etc/NEWSERVICE.conf
        # Execute the required commands inside the deployed system with chroot ${prefix}
        chroot ${prefix} /usr/bin/whatever_command $NEW_VARIABLE
        # Use debconf-set-selections to setup the required parameters during the software installation
        # Learn what parameters are available with debconf-show
        echo "NEWSERVICE-config    NEWSERVICE/ParameterA string $NEW_SERVICE_SERVER" | chroot ${prefix} /usr/bin/debconf-set-selections
    fi
fi
```
