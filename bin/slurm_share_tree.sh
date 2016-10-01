#!/bin/bash
# This script is part of sNow!
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
source /sNow/snow-tools/etc/snow.env

# Create Admin User (snow)
sacctmgr -i create user snow account=root adminlevel=Admin

# Create new projects/groups
i=0
while [  $i -lt ${#SGROUPS_CODES[@]} ]
do
    #DESCR=${${SGROUPS_NAMES[$i]}-${SGROUPS_CODES[$i]}}
    sacctmgr -i -Q add account ${SGROUPS_CODES[$i]} Description="${SGROUPS_NAMES[$i]}" cluster=$CLUSTER fairshare=${SGROUPS_SHARES[$i]}
    let i=i+1
done

# Add new users in the right project/group
i=0
while [  $i -lt ${#SGROUPS_CODES[@]} ]
do
    USERS=$(members ${SGROUPS_CODES[$i]} | sed -e "s/ /,/g")
    echo "Adding the following users ($USERS) to the account ${SGROUPS_CODES[$i]}"
    sacctmgr -i add user $USERS cluster=$CLUSTER Parent=${SGROUPS_CODES[$i]} Account=${SGROUPS_CODES[$i]} fairshare=100
    let i=i+1
done

# List the final fair-share tree
sacctmgr list assoc tree format=cluster,account,user,fairshare

# Modify command
# sacctmgr -i modify account where name=${SGROUPS_CODES[$i]} cluster=$CLUSTER set parent=${SGROUPS_CODES[$i]} fairshare=100
# sacctmgr -i modify user $USERS set fairshare=100
