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
function install_devel_env_hpcnow()
{
    case $OS in
        debian)
            pkgs="iotop iftop htop tmux psmisc byobu vim vim-nox iptraf traceroute pdsh clustershell"
        ;;
        ubuntu)
            pkgs="iotop iftop htop tmux psmisc byobu vim vim-nox iptraf traceroute pdsh clustershell"
        ;;
        rhel|redhat|centos)
            pkgs="iotop iftop htop tmux psmisc byobu vim vim-nox iptraf traceroute pdsh clustershell"
        ;;
        suse|sle[sd]|opensuse)
            pkgs="iotop iftop htop tmux psmisc byobu vim vim-nox iptraf traceroute pdsh clustershell"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
}

function setup_devel_env_hpcnow()
{
    if is_master; then
        install_devel_env_hpcnow 
        #git clone https://github.com/HPCNow/dotfiles.git /tmp/dotfiles
        #cd /tmp/dotfiles
        #bash dotfiles.sh
        git clone https://github.com/squash/sudosh2.git /tmp/sudosh2
        cd /tmp/sudosh2
        ./configure 
        make
        make install 
        sudosh -i 
        rm -fr /tmp/sudosh2
        mkdir -p /usr/share/images/grub
        bkp /etc/default/grub
        echo "GRUB_BACKGROUND=\"/usr/share/images/grub/snow-grub-bg.png\"" >> /etc/default/grub 
        wget http://hpcnow.com/images/snow/snow-grub-bg.png -O /usr/share/images/grub/snow-grub-bg.png
        update-grub
    else
        echo "nothing to do here"
    fi
} 1>>$LOGFILE 2>&1
