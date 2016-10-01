#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#
function setup_snow_user()
{
    # Check UIDs and GIDs
    if [[ -z $(getent passwd $sNow_USER) ]]; then
        groupadd -g $sNow_GID $sNow_GROUP
        useradd -u $sNow_UID -g $sNow_GID -c "sNow! Admin User" -s /bin/bash -d $SNOW_HOME/$sNow_USER  $sNow_USER 
    elif [[ "$(id -u $sNow_USER)" != "$sNow_UID"  &&  "$(id -g $sNow_USER)" != "$sNow_GID" ]]; then
        groupmod -g $sNow_GID $sNow_GROUP
        usermod -u $sNow_UID -g $sNow_GID $sNow_USER
        usermod -c "sNow! Admin User" -g $sNow_GID -d $SNOW_HOME/$sNow_USER -s /bin/bash -m -u $sNow_UID $sNow_USER
    fi
    # Don't require password for sNow! Admin user sudo
    echo "$sNow_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    if is_golden_node; then
        # Configure public key auth for the sNow! Admin User
        mkdir -p $SNOW_HOME/$sNow_USER/.ssh
        # Setup the ACLs to the right user
        chown -R $sNow_USER:$sNow_GROUP $SNOW_HOME/$sNow_USER
    fi
} 1>>$LOGFILE 2>&1

function setup_hpcnow_user()
{
    # Check UIDs and GIDs
    if [[ -z $(getent passwd $HPCNow_USER) ]]; then
        useradd -u $HPCNow_UID -g $HPCNow_GID -c "HPCNow! User" -s /bin/bash -d $SNOW_HOME/$HPCNow_USER  $HPCNow_USER 
    elif [[ "$(id -u $HPCNow_USER)" != "$HPCNow_UID"  &&  "$(id -g $HPCNow_USER)" != "$HPCNow_GID" ]]; then
        usermod -c "HPCNow! User" -g $HPCNow_GID -d $SNOW_HOME/$HPCNow_USER -s /bin/bash -m -u $HPCNow_UID $HPCNow_USER
    fi
    # Don't require password for sNow! Admin user sudo
    echo "$HPCNow_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
} 1>>$LOGFILE 2>&1


function setup_ssh()
{
    setup_snow_user
    if [[ "$HPCNow_Support" != "none" ]]; then
        setup_hpcnow_user
    fi
    mkdir -p /root/.ssh
    cp -p $SNOW_HOME/$sNow_USER/.ssh/authorized_keys /root/.ssh/authorized_keys
    # Allow support for GPFS requirements
    cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub
    cp -p $SNOW_HOME/$sNow_USER/.ssh/id_rsa /root/.ssh/id_rsa
    chown -R root:root /root/.ssh
    chmod 700 /root/.ssh
    chmod 640 /root/.ssh/authorized_keys
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
    ln -sf $SNOW_UTIL/bin/easybuild-source.sh /etc/profile.d/easybuild.sh
    #ln -sf $SNOW_UTIL/bin/easybuild-source.csh /etc/profile.d/easybuild.csh
    #ln -sf $SNOW_UTIL/bin/snow-source.sh /etc/profile.d/snow.sh
    #ln -sf $SNOW_UTIL/bin/snow-source.csh /etc/profile.d/snow.csh
} 1>>$LOGFILE 2>&1

