#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function install_lmod()
{
    ln -sf $SNOW_SOFT/lmod/lmod/init/profile /etc/profile.d/lmod.sh
    ln -sf $SNOW_SOFT/lmod/lmod/init/cshrc /etc/profile.d/lmod.csh
    if is_golden_node; then
        if [[ ! -e $SNOW_SOFT/lmod/lmod/init/profile ]]; then
            chown -R $sNow_USER:$sNow_GROUP $SNOW_SOFT
            su $sNow_USER -c "git clone https://github.com/TACC/Lmod.git /tmp/Lmod; cd /tmp/Lmod; ./configure --prefix=$SNOW_SOFT; make; make install"
        fi
    fi
} 1>>$LOGFILE 2>&1
