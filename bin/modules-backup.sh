#!/bin/bash
#set -xv
# This is a simple script that will create a backup of the snow Domains (VMs/containers)
# The suitability of this script will depend on the institutional backup system.
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

# If you don't want to backup all the domains, change the following line with a list
DOMAINS2BKP=$(snow list| egrep -v "Name|Domain-0"|gawk '{print $1}')

SNOWPATH=$(dirname "$0")
# Load the configuration
CONFIG_FILE=$SNOWPATH/../etc/snow.conf
SNOW_DOMAINS=$SNOWPATH/../etc/active-domains.conf
SELF_ACTIVE_DOMAINS=$(cat $SNOW_DOMAINS | grep -v ^# | cut -d= -f1 | gawk '{print $1}')
#DOMAINS2BKP=${SELF_ACTIVE_DOMAINS:-$DOMAINS2BKP}

if [[ -f $CONFIG_FILE ]]; then
    source $CONFIG_FILE
fi

if [[ -f $SNOW_DOMAINS ]]; then
    source $SNOW_DOMAINS
fi

if ! [[ -d $SNOWROOT/log ]]; then
    mkdir $SNOWROOT/log
fi

if ! [[ -d $SNOWROOT/backup ]]; then
    mkdir $SNOWROOT/backup
fi

for VMNAME in $DOMAINS2BKP 
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
