#!/bin/bash
#set -xv
# This is a simple script that will create a backup of the snow Modules (VMs/containers)
# The suitability of this script will depend on the institutional backup system.
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

SNOWPATH=$(dirname "$0")
# Load the configuration
CONFIG_FILE=$SNOWPATH/../etc/snow.conf
SNOW_MODULES=$SNOWPATH/../etc/active-modules.conf
SELF_ACTIVE_MODULES=$(cat $SNOW_MODULES | grep -v ^# | cut -d= -f1 | gawk '{print $1}')

if [[ -f $CONFIG_FILE ]]; then
    source $CONFIG_FILE
fi

if [[ -f $SNOW_MODULES ]]; then
    source $SNOW_MODULES
fi

if [[ -d ! $SNOWROOT/log ]]; then
    mkdir $SNOWROOT/log
fi

VMNAME=vm.$1
DATE=$(date +%Y%m%d)
LAST=$(tail -1 $SNOWROOT/log/snapshots-$VMNAME.history)

/sbin/lvcreate -s -L 1G -n $VMNAME-snap-$DATE.root $SNOWVG/${VMNAME}_root &> $SNOWROOT/log/snapshots-$VMNAME.log
/sbin/lvcreate -s -L 1G -n $VMNAME-snap-$DATE.var $SNOWVG/${VMNAME}_var &> $SNOWROOT/log/snapshots-$VMNAME.log
echo "$VMNAME-snap-$DATE" >> $SNOWROOT/log/snapshots-$VMNAME.history
dd if=/dev/$SNOWVG/$VMNAME-snap-$DATE.root of=$SNOWROOT/backup/$VMNAME-snap-$DATE.root
dd if=/dev/$SNOWVG/$VMNAME-snap-$DATE.var of=$SNOWROOT/backup/$VMNAME-snap-$DATE.var
bzip2 $SNOWROOT/backup/$VMNAME-snap-$DATE.*
rm $SNOWROOT/backup/$LAST.*.bz2 
/sbin/lvremove -f /dev/$SNOWVG/$LAST.root
/sbin/lvremove -f /dev/$SNOWVG/$LAST.var
echo "Backup de $VMNAME realitzat" | nail -s "[sNow!] Snapshot $VMNAME" -a $SNOWROOT/log/snapshots-$VMNAME.log -r $SMAIL $SMAIL
