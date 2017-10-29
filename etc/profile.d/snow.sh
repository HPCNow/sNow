#!/bin/bash
SNOW_PATH=/sNow
if [[ $(id -u) -eq 0 ]]; then
    export PATH=${SNOW_PATH}/snow-tools/sbin:$PATH
fi
export PATH=${SNOW_PATH}/snow-tools/bin:$PATH
export MANPATH=${SNOW_PATH}/snow-tools/man:$MANPATH
export PDSH_RCMD_TYPE=ssh
