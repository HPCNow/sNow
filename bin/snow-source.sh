#!/bin/bash
SNOW_PATH=/sNow
if [[ $(id -u) -eq 0 || "$USER" == "snow" ]] ; then
    export PATH=${SNOW_PATH}/snow-tools/sbin:$PATH
fi
export PATH=${SNOW_PATH}/snow-tools/bin:$PATH
export PDSH_RCMD_TYPE=ssh
