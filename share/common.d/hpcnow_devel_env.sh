#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
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
        #git clone https://github.com/HPCNow/dotfiles.git /dev/shm/dotfiles
        #cd /dev/shm/dotfiles
        #bash dotfiles.sh
        git clone https://github.com/squash/sudosh2.git /dev/shm/sudosh2
        cd /dev/shm/sudosh2
        ./configure 
        make
        make install 
        sudosh -i 
        mkdir -p /usr/share/images/grub
        bkp /etc/default/grub
        echo "GRUB_BACKGROUND=\"/usr/share/images/grub/snow-grub-bg.png\"" >> /etc/default/grub 
        wget http://hpcnow.com/images/snow/snow-grub-bg.png -O /usr/share/images/grub/snow-grub-bg.png
        update-grub
    else
        echo "nothing to do here"
    fi
} 1>>$LOGFILE 2>&1
