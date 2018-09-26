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
            install_software "apt-transport-https ca-certificates curl gnupg2 software-properties-common"
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
            apt-get -y update
            install_software "docker-ce=${DOCKER_VERSION}~ce-0~debian"
            groupadd docker
            # shellcheck disable=SC2154
            usermod -aG docker $sNow_USER
            systemctl enable docker
            systemctl start docker
        ;;
        ubuntu)
            install_software "apt-transport-https ca-certificates curl gnupg2 software-properties-common"
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            apt-get -y update
            install_software "docker-ce=${DOCKER_VERSION}~ce-0~ubuntu"
            groupadd docker
            usermod -aG docker $sNow_USER
            systemctl enable docker
            systemctl start docker
            echo "GRUB_CMDLINE_LINUX=\"cgroup_enable=memory swapaccount=1\"" >> /etc/default/grub
            update-grub
        ;;
        rhel|redhat|centos)
            yum -y update
            install_software "yum-utils device-mapper-persistent-data lvm2"
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            install_software "docker-ce-${DOCKER_VERSION}.ce"
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
    if is_snow_node; then
        info_msg "Docker is not supported in the master node"
    else
        install_docker
    fi
} 1>>$LOGFILE 2>&1


function setup_docker_swarm_worker()
{
    install_docker
    # Setup Docker Swarm Worker
    SNOW_SWARM_MANAGER=$(gawk '{if($2 ~ /swarm-manager/){print $1}}' $SNOW_ROOT/etc/domains.conf)
    SNOW_SWARM_MANAGER_IP=$(gawk '{if($2 ~ /swarm-manager/){print $4}}' $SNOW_ROOT/etc/domains.conf)
    if  [[ ! -z "$SNOW_SWARM_MANAGER" && ! -z "$SITE_SWARM_MANAGER" ]]; then
        SWARM_MANAGER=$SNOW_SWARM_MANAGER
    else
        SWARM_MANAGER="${SITE_SWARM_MANAGER:-$SNOW_SWARM_MANAGER}"
    fi

    if  [[ ! -z "$SNOW_SWARM_MANAGER_IP" && ! -z "$SITE_SWARM_MANAGER_IP" ]]; then
        SWARM_MANAGER_IP=$SNOW_SWARM_MANAGER_IP
    else
        SWARM_MANAGER_IP="${SITE_SWARM_MANAGER_IP:-$SNOW_SWARM_MANAGER_IP}"
    fi
    # Register node as woker node in the Docker Swarm cluster
    if  [[ ! -z "$SWARM_MANAGER" ]]; then
        # Check if the token file already exists
        if [[ -e ${SNOW_SRV}/deploy_files/etc/docker_swarm.token ]]; then
            mkdir /etc/portainer
            docker swarm join --token "$(cat ${SNOW_SRV}/deploy_files/etc/docker_swarm.token)" ${SWARM_MANAGER_IP}:2377
        else
            check_host_status ${SWARM_MANAGER}
            scp -p ${SWARM_MANAGER}:/root/docker_swarm.token ${SNOW_SRV}/deploy_files/etc/docker_swarm.token
            if [[ -e ${SNOW_SRV}/deploy_files/etc/docker_swarm.token ]]; then
                error_msg "Docker Swarm Worker requires the file ${SNOW_SRV}/deploy_files/etc/docker_swarm.token"
                error_msg "Which is generated once the Docker Swarm manager is booted for first time"
            fi
        fi
    else
        error_msg "Docker Swarm Worker requires a manager already deployed and running"
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
    if is_snow_node; then
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
            replace_text /etc/default/grub "GRUB_CMDLINE_XEN_DEFAULT" "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=8192M,max:8192M dom0_max_vcpus=4 dom0_vcpus_pin\""
            replace_text /etc/default/grub "GRUB_DISABLE_OS_PROBER" "GRUB_DISABLE_OS_PROBER=true"
            replace_text /etc/default/grub "GRUB_CMDLINE_LINUX_DEFAULT" "GRUB_CMDLINE_LINUX_DEFAULT=\"console=tty0 console=ttyS0,115200n8\""
            replace_text /etc/default/grub "GRUB_TERMINAL" "GRUB_TERMINAL=console"
            replace_text /etc/default/grub "GRUB_SERIAL_COMMAND" "#GRUB_SERIAL_COMMAND"
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
            replace_text /etc/default/grub "GRUB_CMDLINE_XEN_DEFAULT" "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=8192M,max:8192M dom0_max_vcpus=4 dom0_vcpus_pin\""
            replace_text /etc/default/grub "GRUB_DISABLE_OS_PROBER" "GRUB_DISABLE_OS_PROBER=true"
            replace_text /etc/default/grub "GRUB_CMDLINE_LINUX_DEFAULT" "GRUB_CMDLINE_LINUX_DEFAULT=\"console=tty0 console=ttyS0,115200n8\""
            replace_text /etc/default/grub "GRUB_TERMINAL" "GRUB_TERMINAL=console"
            replace_text /etc/default/grub "GRUB_SERIAL_COMMAND" "#GRUB_SERIAL_COMMAND"
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
    if is_snow_node; then
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
            echo "deb https://downloads.opennebula.org/repo/${OPENNEBULA_RELEASE}/Debian/${OS_VERSION_MAJOR} stable opennebula" > /etc/apt/sources.list.d/opennebula.list
            pkgs="opennebula-node bridge-utils"
        ;;
        ubuntu)
            echo "deb https://downloads.opennebula.org/repo/${OPENNEBULA_RELEASE}/Ubuntu/${OS_VERSION} stable opennebula" > /etc/apt/sources.list.d/opennebula.list
            pkgs="opennebula-node bridge-utils"
        ;;
        rhel|redhat|centos)
            cp -p ${SNOW_ETC}/config_template.d/opennebula/opennebula_centos.repo /etc/yum.repos.d/opennebula.repo
            replace_text /etc/yum.repos.d/opennebula.repo "^baseurl" "baseurl=https://downloads.opennebula.org/repo/${OPENNEBULA_VERSION}/CentOS/${OS_VERSION_MAJOR}/x86_64"
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
    # Note that if you alredy have oneadmin SSH keys available, sNow! will use those.
    if [[ ! -e $SNOW_SRV/deploy_files/etc/rsa/id_rsa_oneadmin.pub ]]; then
        if [[ ! -e $SNOW_SRV/deploy_files/etc/rsa ]]; then
            mkdir -p $SNOW_SRV/deploy_files/etc/rsa
        fi
        cp -p /var/lib/one/.ssh/id_rsa $SNOW_SRV/deploy_files/etc/rsa/id_rsa_oneadmin
        cp -p /var/lib/one/.ssh/id_rsa.pub $SNOW_SRV/deploy_files/etc/rsa/id_rsa_oneadmin.pub
    else
        if [[ ! -e /var/lib/one/.ssh ]]; then
            mkdir -p /var/lib/one/.ssh
        fi
        cp -p $SNOW_SRV/deploy_files/etc/rsa/id_rsa_oneadmin /var/lib/one/.ssh/id_rsa
        cp -p $SNOW_SRV/deploy_files/etc/rsa/id_rsa_oneadmin.pub /var/lib/one/.ssh/id_rsa.pub
        cp -p /var/lib/one/.ssh/id_rsa.pub /var/lib/one/.ssh/authorized_keys
        chmod 600 /var/lib/one/.ssh/authorized_keys
        chmod 400 /var/lib/one/.ssh/id_rsa
        chown -R oneadmin:oneadmin /var/lib/one/
    fi
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
                replace_text /etc/sysconfig/network-scripts/ifcfg-br$i "^BRIDGE" "BRIDGE=\"br$i\""
                replace_text /etc/sysconfig/network-scripts/ifcfg-br$i "^TYPE" "TYPE=\"Bridge\""
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
    if is_snow_node; then
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
        SNOW_OPENNEBULA_SERVER=$(gawk '{if($2 ~ /opennebula-fe/){print $1}}' $SNOW_ROOT/etc/domains.conf)
        ssh ${SNOW_OPENNEBULA_SERVER} onehost create "$(uname -n)" -i kvm -v kvm
    fi
} 1>>$LOGFILE 2>&1
