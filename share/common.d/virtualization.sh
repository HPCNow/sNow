#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

function install_docker()
{
    case $OS in
        debian)
            apt-get -y purge lxc-docker*
            apt-get -y purge docker.io*
            apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
            echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
            apt-get -y update
            apt-cache policy docker-engine
            apt-get -y install docker-engine
            groupadd docker
            gpasswd -a $sNow_USER docker
            service docker restart
        ;;
        ubuntu)
            apt-get -y install linux-image-extra-$(uname -r)
            apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
            echo "deb https://apt.dockerproject.org/repo ubuntu-wily main" > /etc/apt/sources.list.d/docker.list
            apt-get -y update
            apt-get -y purge lxc-docker
            apt-cache policy docker-engine
            apt-get -y install docker-engine
            usermod -aG docker $sNow_USER
            echo "GRUB_CMDLINE_LINUX=\"cgroup_enable=memory swapaccount=1\"" >> /etc/default/grub
            update-grub
            service docker start
            systemctl enable docker
        ;;
        rhel|redhat|centos)
            yum -y update
            curl -sSL https://get.docker.com/ | sh
            usermod -aG docker $sNow_USER
            chkconfig docker on
            service docker start
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
        curl -L https://github.com/docker/compose/releases/download/1.6.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
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
            gawk 'BEGIN{grub_cmdline=0}{
                
                if($1 ~ /GRUB_CMDLINE_XEN_DEFAULT/){
                    print "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=3188M,max:5875M dom0_max_vcpus=2 dom0_vcpus_pin\""
                    grub_cmdline=1
                }
                else{
                    print $0
                }
            }
            END{
                if(grub_cmdline == 0){
                    print "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=3188M,max:5875M  dom0_max_vcpus=2 dom0_vcpus_pin\""
                }
            }' /etc/default/grub > /etc/default/grub.1
            mv /etc/default/grub.1 /etc/default/grub
            echo 'GRUB_DISABLE_OS_PROBER=true' >> /etc/default/grub
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
            install_software "xen-linux-system xen-tools"
            dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
            sed -i '/TOOLSTACK/s/=.*/=xl/' /etc/default/xen
            sed -i 's/GRUB_CMDLINE_XEN_DEFAULT=/GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=4096M,max:4096M dom0_max_vcpus=2 dom0_vcpus_pin\"/' /etc/default/grub
            echo 'GRUB_DISABLE_OS_PROBER=true' >> /etc/default/grub
            sed -i 's/(dom0-min-mem 1024)/(dom0-min-mem 4096)/' /etc/xen/xend-config.sxp
            sed -i 's/(dom0-cpus 2)/(dom0-min-mem 4096)/' /etc/xen/xend-config.sxp
            sed -i 's/XENDOMAINS_RESTORE=true/XENDOMAINS_RESTORE=false/' /etc/default/xendomains
            sed -i 's/XENDOMAINS_SAVE=\/var\/lib\/xen\/save/XENDOMAINS_SAVE=/' /etc/default/xendomains
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
