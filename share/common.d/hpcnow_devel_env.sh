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
            if ! is_master; then
                pkgs="$pkgs Lmod tcl tcl-devel"
            fi
        ;;
        ubuntu)
            pkgs="build-essential libbz2-1.0 libssl-dev nfs-client rpcbind curl wget gawk libibverbs libibverbs-devel python-devel python-pip apt-transport-https ca-certificates members git parallel vim"
            if ! is_master; then
                pkgs="$pkgs Lmod tcl tcl-devel"
            fi
        ;;
        rhel|redhat|centos)
            pkgs="epel-release @base @development-tools lsb libdb flex perl perl-Data-Dumper perl-Digest-MD5 perl-JSON perl-Parse-CPAN-Meta perl-CPAN pcre pcre-devel zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs nfs-utils rpcbind mdadm wget curl gawk patch unzip libibverbs libibverbs-devel python-devel python-pip members git parallel vim"
            if ! is_master; then
                pkgs="$pkgs Lmod tcl tcl-devel"
            fi
        ;;
        suse|sle[sd]|opensuse)
            pkgs="libbz2-1 libz1 openssl libopenssl-devel gcc gcc-c++ nfs-client rpcbind wget curl gawk libibverbs libibverbs-devel python-devel python-pip members git parallel vim"
            if ! is_master; then
                pkgs="$pkgs Lmod tcl tcl-devel"
            fi
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
        git clone https://github.com/HPCNow/dotfiles.git /dev/shm/dotfiles
        cd /dev/shm/dotfiles
        bash dotfiles.sh
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
