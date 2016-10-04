#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function install_easybuild()
{
    ln -sf $SNOW_TOOL/bin/easybuild-source.sh /etc/profile.d/easybuild.sh
    #ln -sf $SNOW_TOOL/bin/easybuild-source.csh /etc/profile.d/easybuild.csh
    if is_golden_node; then
        if [[ ! -e $SNOW_SOFT/modules/all ]]; then
            chown -R $sNow_USER:$sNow_GROUP $SNOW_SOFT
            cd $SNOW_SOFT
            curl -O https://raw.githubusercontent.com/hpcugent/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py
            su - $sNow_USER -c "python $SNOW_SOFT/bootstrap_eb.py $SNOW_SOFT"
        fi
    fi
} 1>>$LOGFILE 2>&1
