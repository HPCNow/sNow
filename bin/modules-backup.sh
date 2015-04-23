#!/bin/bash
#set -xv
# This is a simple script that will create a backup of the snow Modules (VMs/containers)
# The suitability of this script will depend on the institutional backup system.
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

# If you don't want to backup all the modules, change the following line with a list
MODULES2BKP=$(snow list| egrep -v "Name|Domain-0"|gawk '{print $1}')

SNOWPATH=$(dirname "$0")
# Load the configuration
CONFIG_FILE=$SNOWPATH/../etc/snow.conf
SNOW_MODULES=$SNOWPATH/../etc/active-modules.conf
SELF_ACTIVE_MODULES=$(cat $SNOW_MODULES | grep -v ^# | cut -d= -f1 | gawk '{print $1}')
#MODULES2BKP=${SELF_ACTIVE_MODULES:-$MODULES2BKP}

if [[ -f $CONFIG_FILE ]]; then
    source $CONFIG_FILE
fi

if [[ -f $SNOW_MODULES ]]; then
    source $SNOW_MODULES
fi

if ! [[ -d $SNOWROOT/log ]]; then
    mkdir $SNOWROOT/log
fi

if ! [[ -d $SNOWROOT/backup ]]; then
    mkdir $SNOWROOT/backup
fi

for VMNAME in $MODULES2BKP 
do 
    DATE=$(date +%Y%m%d)
    LAST=$(tail -1 $SNOWROOT/log/snapshots-$VMNAME.history)
    /sbin/lvcreate -s -L 1G -n $VMNAME-snap-$DATE $SNOWVG/${VMNAME} &> $SNOWROOT/log/snapshots-$VMNAME.log
    echo "$VMNAME-snap-$DATE" >> $SNOWROOT/log/snapshots-$VMNAME.history
    dd if=/dev/$SNOWVG/$VMNAME-snap-$DATE of=$SNOWROOT/backup/$VMNAME-snap-$DATE
    bzip2 $SNOWROOT/backup/$VMNAME-snap-$DATE
    rm $SNOWROOT/backup/$LAST.bz2 
    /sbin/lvremove -f /dev/$SNOWVG/$LAST
    #echo "Backup module $VMNAME finished" | nail -s "[sNow!] Snapshot $VMNAME" -a $SNOWROOT/log/snapshots-$VMNAME.log -r $SMAIL $SMAIL
    echo "Backup module $VMNAME finished" | logger -t snow -p user.notice
done
