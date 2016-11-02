#!/bin/bash
SNOWROOT=/sNow
if [[ $(id -u) -eq 0 || "$USER" == "snow" ]] ; then
    export PATH=$SNOWROOT/snow-tools/sbin:$PATH
fi
export PATH=$SNOWROOT/snow-tools/bin:$PATH
#export LC_ALL=C 
