#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then
    export PATH=${SNOW_SBIN}:$PATH
fi
export PATH=${SNOW_BIN}:$PATH
export PDSH_RCMD_TYPE=ssh