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
function setup_user()
{
    local user_name=$1
    local user_uid=$2
    local user_gid=$3
    local user_group=$4
    local user_sudoers=$5
    local user_shell=$6
    local user_gecos="$7"

    if [[ $# -lt 7 ]]; then
        error_exit "User ${user_name} can not be created because some parameters are missing."
    fi

    if [[ -z $(getent passwd ${user_name}) ]]; then
        bkp /etc/group
        bkp /etc/passwd
        bkp /etc/shadow
        groupadd -g ${user_gid} ${user_group}
        useradd -u ${user_uid} -g ${user_gid} -c "${user_gecos}" -s ${user_shell} -d $SNOW_HOME/${user_name}  ${user_name}
    elif [[ "$(id -u ${user_name})" != "${user_uid}"  &&  "$(id -g ${user_name})" != "${user_gid}" ]]; then
        groupmod -g ${user_gid} ${user_group}
        usermod -u ${user_uid} -g ${user_gid} ${user_name}
        usermod -c "${user_gecos}" -g ${user_gid} -d $SNOW_HOME/${user_name} -s ${user_shell} -m -u ${user_uid} ${user_name}
    fi

    if [[ "${user_sudoers}" == "true" ]]; then
        bkp /etc/sudoers
        echo "${user_name} ALL=(ALL) ALL" >> /etc/sudoers
    fi

    if [[ "${user_sudoers}" == "nopasswd" ]]; then
        bkp /etc/sudoers
        echo "${user_name} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi

    if [[ ! -f $SNOW_HOME/${user_name}/.ssh/id_rsa ]]; then
        if [[ ! -e $SNOW_HOME/${user_name}/.ssh ]]; then
            mkdir -p $SNOW_HOME/${user_name}/.ssh
            chown -R ${user_name}:${user_group} $SNOW_HOME/${user_name}/.ssh
        fi
        # Note that if you already have SSH keys available, sNow! will use those.
        if [[ ! -e $SNOW_CONF/system_files/etc/rsa/id_rsa_${user_name}.pub ]]; then
            if [[ ! -e $SNOW_CONF/system_files/etc/rsa ]]; then
                mkdir -p $SNOW_CONF/system_files/etc/rsa
            fi
            sudo -u ${user_name} ssh-keygen -t rsa -f $SNOW_HOME/${user_name}/.ssh/id_rsa -q -P ""
            cp -p $SNOW_HOME/${user_name}/.ssh/id_rsa $SNOW_CONF/system_files/etc/rsa/id_rsa_${user_name}
            cp -p $SNOW_HOME/${user_name}/.ssh/id_rsa.pub $SNOW_CONF/system_files/etc/rsa/id_rsa_${user_name}.pub
        else
            cp -p $SNOW_CONF/system_files/etc/rsa/id_rsa_${user_name} $SNOW_HOME/${user_name}/.ssh/id_rsa
            cp -p $SNOW_CONF/system_files/etc/rsa/id_rsa_${user_name}.pub $SNOW_HOME/${user_name}/.ssh/id_rsa.pub
        fi
        bkp $SNOW_HOME/${user_name}/.ssh/authorized_keys
        cp -p $SNOW_HOME/${user_name}/.ssh/id_rsa.pub $SNOW_HOME/${user_name}/.ssh/authorized_keys
        chmod 600 $SNOW_HOME/${user_name}/.ssh/authorized_keys
        chmod 400 $SNOW_HOME/${user_name}/.ssh/id_rsa
        echo "Host *" > $SNOW_HOME/${user_name}/.ssh/config
        echo "    StrictHostKeyChecking no" >> $SNOW_HOME/${user_name}/.ssh/config
        echo "    UserKnownHostsFile /dev/null" >> $SNOW_HOME/${user_name}/.ssh/config
        echo "    PasswordAuthentication no" >> $SNOW_HOME/${user_name}/.ssh/config
        chown -R ${user_name}:${user_group} $SNOW_HOME/${user_name}/.ssh/
    fi
} 1>>$LOGFILE 2>&1

function setup_ssh()
{
    # Users Setup
    if [[ ! -z "${MASTER_PASSWORD}" ]]; then
        echo "root:${MASTER_PASSWORD}" | chpasswd
    fi
    # shellcheck disable=SC2154
    setup_user "${sNow_USER}" "${sNow_UID}" "${sNow_GID}" "${sNow_GROUP}" "nopasswd" "/bin/bash" "sNow! Admin User"
    # shellcheck disable=SC2154
    if [[ "${HPCNow_Support}" != "none" ]]; then
        setup_user "${HPCNow_USER}" "${HPCNow_UID}" "${HPCNow_GID}" "${HPCNow_GROUP}" "nopasswd" "/bin/bash" "HPCNow! Admin User"
    fi
    # Setup SSH keys
    if [[ -e $SNOW_CONF/system_files/etc/rsa/id_rsa_${sNow_USER}.pub ]]; then
        if [[ ! -e /root/.ssh ]]; then
            mkdir -p /root/.ssh
        fi
        cp -p $SNOW_CONF/system_files/etc/rsa/id_rsa_${sNow_USER} /root/.ssh/id_rsa
        cp -p $SNOW_CONF/system_files/etc/rsa/id_rsa_${sNow_USER}.pub /root/.ssh/id_rsa.pub
        bkp /root/.ssh/authorized_keys
        cp -p /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
        chmod 700 /root/.ssh
        chmod 600 /root/.ssh/authorized_keys
        chmod 400 /root/.ssh/id_rsa
        chown -R root:root /root/.ssh
    else
        error_msg "sNow! SSH keys not yet generated"
    fi
    # Setup host based authentication
    cp -pr $SNOW_CONF/system_files/etc/ssh/ssh_host_* /etc/ssh/
    if [[ -e $SNOW_CONF/system_files/etc/ssh/shosts.equiv ]]; then
        cp -p $SNOW_CONF/system_files/etc/ssh/shosts.equiv /etc/ssh/
    fi
    if [[ -e $SNOW_CONF/system_files/etc/ssh/ssh_known_hosts ]]; then
        cp -p $SNOW_CONF/system_files/etc/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts
    fi
    if [[ -e /usr/lib64/ssh/ssh-keysign ]]; then
        chmod u+s /usr/lib64/ssh/ssh-keysign
    fi
    if [[ -e /usr/libexec/openssh/ssh-keysign ]]; then
        chmod u+s /usr/libexec/openssh/ssh-keysign
    fi
    if [[ -e /etc/ssh/shosts.equiv ]]; then
        cp -p /etc/ssh/shosts.equiv /root/.shosts
    fi
    sed -i "s/RhostsRSAAuthentication no/RhostsRSAAuthentication yes/g" /etc/ssh/sshd_config
    sed -i "s/HostbasedAuthentication no/HostbasedAuthentication yes/g" /etc/ssh/sshd_config
    sed -i "s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g" /etc/ssh/ssh_config
    echo "GSSAPIAuthentication yes" >> /etc/ssh/sshd_config
    echo "GSSAPICleanupCredentials yes" >> /etc/ssh/sshd_config
    echo "HostbasedUsesNameFromPacketOnly yes" >> /etc/ssh/sshd_config
    echo "IgnoreRhosts no" >> /etc/ssh/sshd_config
    echo "UseDNS no" >> /etc/ssh/sshd_config
    systemctl restart sshd
} 1>>$LOGFILE 2>&1

function setup_env()
{
    # Set unlimited mem lock
    echo "* hard memlock unlimited" >> /etc/security/limits.conf
    echo "* soft memlock unlimited" >> /etc/security/limits.conf
    # User enviroment setup
    ln -sf $SNOW_TOOL/bin/snow-source.sh /etc/profile.d/snow.sh
    ln -sf $SNOW_TOOL/bin/snow-source.csh /etc/profile.d/snow.csh
} 1>>$LOGFILE 2>&1
