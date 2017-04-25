#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
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
        #su - $sNow_USER -c "cd $SNOW_CONF/docker_files; docker-compose up -d"
    else
        echo "Nothing to be done yet"
    fi
} 1>>$LOGFILE 2>&1

function install_lxd()
{
    case $OS in
        debian)
            echo "sNow! LXD Support not yet available for $OS"
            exit 1
        ;;
        ubuntu)
            apt-get -y install lxd zfsutils-linux
        ;;
        rhel|redhat|centos)
            echo "sNow! LXD Support not yet available for $OS"
            exit 1
       ;;
       suse|sle[sd]|opensuse)
            echo "sNow! LXD Support not yet available for $OS"
            exit 1
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
            # Following suggestions from Debian : https://wiki.debian.org/Xen
            if [[ -f /etc/default/cpufrequtils ]]; then
                bkp /etc/default/cpufrequtils
                sed -i '/GOVERNOR/s/=.*/="performance"/' /etc/default/cpufrequtils
            fi
            apt-get -y update
            install_software "xen-linux-system xen-tools"
            dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
            sed -i '/TOOLSTACK/s/=.*/=xl/' /etc/default/xen
            bkp /etc/default/grub
            replace_text /etc/default/grub "GRUB_CMDLINE_XEN_DEFAULT" "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=3188M,max:5875M dom0_max_vcpus=2 dom0_vcpus_pin\""
            replace_text /etc/default/grub "GRUB_DISABLE_OS_PROBER" "GRUB_DISABLE_OS_PROBER=true"
            bkp /etc/default/xendomains
            sed -i 's/XENDOMAINS_RESTORE=true/XENDOMAINS_RESTORE=false/' /etc/default/xendomains
            sed -i 's/XENDOMAINS_SAVE=\/var\/lib\/xen\/save/XENDOMAINS_SAVE=/' /etc/default/xendomains
            bkp /etc/sysctl.conf
            sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
        ;;
        ubuntu)
            # Following suggestions from Debian : https://wiki.debian.org/Xen
            sed -i '/GOVERNOR/s/=.*/="performance"/' /etc/default/cpufrequtils
            apt-get -y update
            install_software "cpufrequtils xen-system xen-tools"
            dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
            sed -i '/TOOLSTACK/s/=.*/=xl/' /etc/default/xen
            bkp /etc/default/grub
            replace_text /etc/default/grub "GRUB_CMDLINE_XEN_DEFAULT" "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=3188M,max:5875M dom0_max_vcpus=2 dom0_vcpus_pin\""
            replace_text /etc/default/grub "GRUB_DISABLE_OS_PROBER" "GRUB_DISABLE_OS_PROBER=true"
            bkp /etc/default/xendomains
            sed -i 's/XENDOMAINS_RESTORE=true/XENDOMAINS_RESTORE=false/' /etc/default/xendomains
            sed -i 's/XENDOMAINS_SAVE=\/var\/lib\/xen\/save/XENDOMAINS_SAVE=/' /etc/default/xendomains
            bkp /etc/sysctl.conf
            sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
        ;;
        centos)
            echo "sNow! Xen Support not yet available for RHEL and CentOS"
            exit 1
            yum -y install centos-release-xen bridge-utils SDL net-tools
            yum -y update
            yum -y install xen
            systemctl stop NetworkManager
            systemctl disable NetworkManager
       ;;
        rhel|redhat)
            echo "sNow! Xen Support not yet available for RHEL and CentOS"
            exit 1
            yum -y install xen kernel-xen
       ;;
       suse|sle[sd]|opensuse)
            echo "sNow! Xen Support not yet available for SLES and OpenSUSE"
            exit 1
            zypper -n --no-gpg-checks in -t pattern xen_server
       ;;
   esac
}

function setup_xen()
{
    install_xen
} 1>>$LOGFILE 2>&1
