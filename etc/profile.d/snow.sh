#!/bin/bash
SNOW_ROOT=/sNow
if [[ $(id -u) -eq 0 ]]; then
    export PATH=${SNOW_ROOT}/snow-tools/sbin:$PATH
fi
export PATH=${SNOW_ROOT}/snow-tools/bin:$PATH
export MANPATH=${SNOW_ROOT}/snow-tools/man:$MANPATH
export PDSH_RCMD_TYPE=ssh
