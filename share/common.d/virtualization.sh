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
function install_docker()
{
    case $OS in
        debian)
            apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
            apt-get -y update
            apt-get -y install docker-ce
            groupadd docker
            # shellcheck disable=SC2154
            usermod -aG docker $sNow_USER
            systemctl enable docker
            systemctl start docker
        ;;
        ubuntu)
            apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            apt-get -y update
            apt-get -y install docker-ce
            groupadd docker
            usermod -aG docker $sNow_USER
            systemctl enable docker
            systemctl start docker
            echo "GRUB_CMDLINE_LINUX=\"cgroup_enable=memory swapaccount=1\"" >> /etc/default/grub
            update-grub
        ;;
        rhel|redhat|centos)
            yum -y update
            curl -sSL https://get.docker.com/ | sh
            usermod -aG docker $sNow_USER
            systemctl start docker
            systemctl enable docker
        ;;
        suse|sle[sd]|opensuse)
            zypper -n --no-gpg-checks in docker
            /usr/sbin/usermod -a -G docker $sNow_USER
            echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
            sysctl -p /etc/sysctl.conf
            systemctl start docker
            systemctl enable docker
        ;;
    esac
}

function setup_docker()
{
    if is_master; then
        install_docker
        curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        echo "Nothing to be done yet"
    fi
} 1>>$LOGFILE 2>&1

function install_lxd()
{
    case $OS in
        debian)
            error_msg "sNow! LXD Support not yet available for $OS"
        ;;
        ubuntu)
            apt-get -y install lxd zfsutils-linux
        ;;
        rhel|redhat|centos)
            error_msg "sNow! LXD Support not yet available for $OS"
       ;;
       suse|sle[sd]|opensuse)
            error_msg "sNow! LXD Support not yet available for $OS"
       ;;
   esac
}

function setup_lxd()
{
    if is_master; then
        install_lxd
    else
        echo "Nothing to be done yet"
    fi
} 1>>$LOGFILE 2>&1



function install_xen()
{
    case $OS in
        debian)
            apt-get -y update
            install_software "cpufrequtils xen-system xen-tools"
            # Following suggestions from Debian : https://wiki.debian.org/Xen
            if [[ -e /etc/default/cpufrequtils ]]; then
                bkp /etc/default/cpufrequtils
            else
                touch /etc/default/cpufrequtils
            fi
            replace_text /etc/default/cpufrequtils "^GOVERNOR" "GOVERNOR=performance"
            dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
            sed -i '/TOOLSTACK/s/=.*/=xl/' /etc/default/xen
            bkp /etc/default/grub
            replace_text /etc/default/grub "GRUB_CMDLINE_XEN_DEFAULT" "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=8192M,max:8192M dom0_max_vcpus=2 dom0_vcpus_pin\""
            replace_text /etc/default/grub "GRUB_DISABLE_OS_PROBER" "GRUB_DISABLE_OS_PROBER=true"
            bkp /etc/default/xendomains
            sed -i 's/XENDOMAINS_RESTORE=true/XENDOMAINS_RESTORE=false/' /etc/default/xendomains
            sed -i 's/XENDOMAINS_SAVE=\/var\/lib\/xen\/save/XENDOMAINS_SAVE=/' /etc/default/xendomains
            bkp /etc/sysctl.conf
            sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
            bkp /etc/xen/xl.conf
            replace_text /etc/xen/xl.conf "#autoballoon" "autoballoon=0"
            replace_text /etc/modules "loop" "loop max_loop=64"
        ;;
        ubuntu)
            apt-get -y update
            install_software "cpufrequtils xen-system-amd64 xen-tools"
            # Following suggestions from Debian : https://wiki.debian.org/Xen
            if [[ -e /etc/default/cpufrequtils ]]; then
                bkp /etc/default/cpufrequtils
            else
                touch /etc/default/cpufrequtils
            fi
            replace_text /etc/default/cpufrequtils "^GOVERNOR" "GOVERNOR=performance"
            dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
            sed -i '/TOOLSTACK/s/=.*/=xl/' /etc/default/xen
            bkp /etc/default/grub
            replace_text /etc/default/grub "GRUB_CMDLINE_XEN_DEFAULT" "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=8192M,max:8192M dom0_max_vcpus=2 dom0_vcpus_pin\""
            replace_text /etc/default/grub "GRUB_DISABLE_OS_PROBER" "GRUB_DISABLE_OS_PROBER=true"
            bkp /etc/default/xendomains
            sed -i 's/XENDOMAINS_RESTORE=true/XENDOMAINS_RESTORE=false/' /etc/default/xendomains
            sed -i 's/XENDOMAINS_SAVE=\/var\/lib\/xen\/save/XENDOMAINS_SAVE=/' /etc/default/xendomains
            bkp /etc/sysctl.conf
            sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
            bkp /etc/xen/xl.conf
            replace_text /etc/xen/xl.conf "#autoballoon" "autoballoon=0"
            replace_text /etc/modules "loop" "loop max_loop=64"
        ;;
        centos)
            error_msg "sNow! Xen Support not yet available for RHEL and CentOS"
            yum -y install centos-release-xen bridge-utils SDL net-tools
            yum -y update
            yum -y install xen
            systemctl stop NetworkManager
            systemctl disable NetworkManager
       ;;
        rhel|redhat)
            error_msg "sNow! Xen Support not yet available for RHEL and CentOS"
            yum -y install xen kernel-xen
       ;;
       suse|sle[sd]|opensuse)
            error_msg "sNow! Xen Support not yet available for SLES and OpenSUSE"
            zypper -n --no-gpg-checks in -t pattern xen_server
       ;;
   esac
}

function setup_xen()
{
    install_xen
} 1>>$LOGFILE 2>&1


function install_singularity()
{
    case $OS in
        debian|ubuntu)
            pkgs="singularity-container"
        ;;
        rhel|redhat|centos)
            pkgs="singularity"
        ;;
        suse|sle[sd]|opensuse)
            pkgs="singularity"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
}

function setup_singularity()
{
    if is_master; then
        info_msg "Singularity is not supported in the master node"
    else
        install_singularity
    fi
} 1>>$LOGFILE 2>&1

function install_opennebula()
{
    add_repo_key https://downloads.opennebula.org/repo/repo.key
    case $OS in
        debian)
            echo "deb https://downloads.opennebula.org/repo/${OPENNEBULA_RELEASE}/Debian/${OS_VERSION} stable opennebula" > /etc/apt/sources.list.d/opennebula.list
            pkgs="opennebula-node bridge-utils"
        ;;
        ubuntu)
            echo "deb https://downloads.opennebula.org/repo/${OPENNEBULA_RELEASE}/Ubuntu/${OS_VERSION} stable opennebula" > /etc/apt/sources.list.d/opennebula.list
            pkgs="opennebula-node bridge-utils"
        ;;
        rhel|redhat|centos)
            pkgs="opennebula-node-kvm bridge-utils"
        ;;
        suse|sle[sd]|opensuse)
            error_msg "This distribution is not yet supported in OpenNebula for sNow!."
            # review https://en.opensuse.org/SDB:Cloud_OpenNebula
            pkgs="opennebula-node-kvm bridge-utils"
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
    install_software "$pkgs"
    case $OS in
        debian|ubuntu)
            systemctl restart libvirtd
            systemctl restart libvirt-bin
        ;;
        rhel|redhat|centos)
            systemctl restart libvirtd
        ;;
        suse|sle[sd]|opensuse)
            systemctl restart libvirtd
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
}

function setup_network_bridges()
{
    case $OS in
        debian)
            bkp /etc/network/interfaces
            cp -p /etc/network/interfaces /etc/network/interfaces.tmp
            cat /etc/network/interfaces.tmp | gawk 'BEGIN{n=0}{if($1 ~ /^iface$/ && $2 !~ /lo/){print "auto br"n"\n"$1" br"n" "$3" "$4" "$5"\n    bridge_ports "$2; n++}}' > /etc/network/interfaces
            rm -f /etc/network/interfaces.tmp
        ;;
        rhel|redhat|centos)
            for n in $(ip -o link show | awk -F': ' '{print $2}' | grep -v "^lo$"); do
                i=$(($i+1))
                bkp /etc/sysconfig/network-scripts/ifcfg-$n
                cp -p /etc/sysconfig/network-scripts/ifcfg-$n /etc/sysconfig/network-scripts/ifcfg-br$i
                replace_text /etc/sysconfig/network-scripts/ifcfg-$i "^BRIDGE" "BRIDGE=\"br$i\""
                replace_text /etc/sysconfig/network-scripts/ifcfg-$i "^TYPE" "TYPE=\"Bridge\""
                echo "DEVICE=$n\n TYPE=Ethernet\n BOOTPROTO=none\n ONBOOT=yes\n NM_CONTROLLED=no\n BRIDGE=br$i" > /etc/sysconfig/network-scripts/ifcfg-$n
            done
        ;;
        suse|sle[sd]|opensuse)
            error_msg "This distribution is not supported."
        ;;
        *)
            warning_msg "This distribution is not supported."
        ;;
    esac
}

function setup_opennebula()
{
    if is_master; then
        info_msg "OpenNebula is not supported in the master node"
    else
        install_opennebula
        # LDAP authentication
        # Review: http://docs.opennebula.org/5.4/deployment/authentication_setup/ldap.html
        #setup_opennebula_ldap_auth
        #setup_opennebula_network ${OPENNEBULA_NETWORK_MODE}
        setup_network_bridges
        # First iteration supports only KVM
        # For LXD support review https://github.com/OpenNebula/addon-lxdone/blob/master/Setup.md
        onehost create "$(uname -n)" -i kvm -v kvm
    fi
} 1>>$LOGFILE 2>&1
