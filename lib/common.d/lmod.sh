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
function install_lmod()
{
    case $OS in
        debian|ubuntu)
            pkgs="lua5.2 lua-filesystem lua-posix liblua5.2-dev"
        ;;
        rhel|redhat|centos)
            pkgs="lua-devel lua-filesystem lua-posix"
        ;;
        suse|sle[sd]|opensuse)
            pkgs="lua lua-devel lua-luafilesystem lua-luaposix"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
    if is_golden_node; then
        if [[ ! -e $SNOW_SOFT/lmod/lmod/init/profile ]]; then
            chown -R $sNow_USER:$sNow_GROUP $SNOW_SOFT
            cd $SNOW_SOFT
            su $sNow_USER -c "unset https_proxy; git clone https://github.com/TACC/Lmod.git /tmp/Lmod; cd /tmp/Lmod; ./configure --prefix=$SNOW_SOFT; make; make install"
            rm -fr /tmp/Lmod
        fi
    fi
    ln -sf $SNOW_SOFT/lmod/lmod/init/profile /etc/profile.d/lmod.sh
    ln -sf $SNOW_SOFT/lmod/lmod/init/cshrc /etc/profile.d/lmod.csh
} 1>>$LOGFILE 2>&1
