#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
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

    if [[ $# < 7 ]]; then
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
        sudo -u ${user_name} ssh-keygen -t rsa -f $SNOW_HOME/${user_name}/.ssh/id_rsa -q -P ""
        bkp $SNOW_HOME/${user_name}/.ssh/authorized_keys
        cat $SNOW_HOME/${user_name}/.ssh/id_rsa.pub > $SNOW_HOME/${user_name}/.ssh/authorized_keys
        echo "Host *" > $SNOW_HOME/${user_name}/.ssh/config
        echo "    StrictHostKeyChecking no" >> $SNOW_HOME/${user_name}/.ssh/config
        echo "    UserKnownHostsFile /dev/null" >> $SNOW_HOME/${user_name}/.ssh/config
        echo "    PasswordAuthentication no" >> $SNOW_HOME/${user_name}/.ssh/config
        chown ${user_name}:${user_group} $SNOW_HOME/${user_name}/.ssh/authorized_keys
        chown ${user_name}:${user_group} $SNOW_HOME/${user_name}/.ssh/config
    fi
} 1>>$LOGFILE 2>&1

function setup_ssh()
{
    # Users Setup
    if [[ ! -z "${MASTER_PASSWORD}" ]]; then
        echo "root:${MASTER_PASSWORD}" | chpasswd
    fi
    setup_user "${sNow_USER}" "${sNow_UID}" "${sNow_GID}" "${sNow_GROUP}" "nopasswd" "/bin/bash" "sNow! Admin User"
    if [[ "${HPCNow_Support}" != "none" ]]; then
        setup_user "${HPCNow_USER}" "${HPCNow_UID}" "${HPCNow_GID}" "${HPCNow_GROUP}" "nopasswd" "/bin/bash" "HPCNow! Admin User"
    fi
    # Setup SSH
    mkdir -p /root/.ssh
    cp -p $SNOW_HOME/$sNow_USER/.ssh/authorized_keys /root/.ssh/authorized_keys
    # Allow support for GPFS requirements
    cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub
    cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa /root/.ssh/id_rsa
    chown -R root:root /root/.ssh
    chmod 700 /root/.ssh
    chmod 640 /root/.ssh/authorized_keys
    chmod 400 /root/.ssh/id_rsa
    cp -pr $SNOW_CONF/system_files/etc/ssh/ssh_host_* /etc/ssh/
    cp -p $SNOW_CONF/system_files/etc/ssh/shosts.equiv /etc/ssh/
    cp -p $SNOW_CONF/system_files/etc/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts
    if [[ -e /usr/lib64/ssh/ssh-keysign ]]; then
        chmod u+s /usr/lib64/ssh/ssh-keysign
    fi
    if [[ -e /usr/libexec/openssh/ssh-keysign ]]; then
        chmod u+s /usr/libexec/openssh/ssh-keysign
    fi
    cp -p /etc/ssh/shosts.equiv /root/.shosts
    sed -i "s/RhostsRSAAuthentication no/RhostsRSAAuthentication yes/g" /etc/ssh/sshd_config
    sed -i "s/HostbasedAuthentication no/HostbasedAuthentication yes/g" /etc/ssh/sshd_config
    sed -i "s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g" /etc/ssh/ssh_config
    echo "GSSAPIAuthentication yes" >> /etc/ssh/sshd_config
    echo "GSSAPICleanupCredentials yes" >> /etc/ssh/sshd_config
    echo "HostbasedUsesNameFromPacketOnly yes" >> /etc/ssh/sshd_config
    echo "IgnoreRhosts no" >> /etc/ssh/sshd_config
    echo "HostbasedUsesNameFromPacketOnly yes" >> /etc/ssh/sshd_config
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

