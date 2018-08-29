#!/bin/bash
#
# This file contains the common functions used by sNow! Command Line Interface
# Copyright (C) 2008 Jordi Blasco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# sNow! Cluster Suite is an opensource project developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website: www.hpcnow.com/snow
#
function install_easybuild()
{
    ln -sf $SNOW_TOOL/bin/easybuild-source.sh /etc/profile.d/easybuild.sh
    #ln -sf $SNOW_TOOL/bin/easybuild-source.csh /etc/profile.d/easybuild.csh
    if is_golden_node; then
        if [[ ! -e $SNOW_SOFT/modules/all/EasyBuild ]]; then
            chown -R $sNow_USER:$sNow_GROUP $SNOW_SOFT
            cd $SNOW_SOFT
            curl -O https://raw.githubusercontent.com/hpcugent/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py
            su - $sNow_USER -c "python $SNOW_SOFT/bootstrap_eb.py $SNOW_SOFT"
            su - $sNow_USER -c "mkdir -p $SNOW_SOFT/log/tmp $SNOW_SOFT/jobs"
        fi
    fi
} 1>>$LOGFILE 2>&1
