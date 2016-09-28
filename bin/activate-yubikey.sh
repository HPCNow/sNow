#!/bin/bash
# script to setup 2-factor Yubikey authentication
# Developed by Jordi Blasco (HPCNow! www.hpcnow.com)
echo "
=======================================================================
sNow! will integrate 2-factor authentication based on Yubikey for your 
user account.
=======================================================================
"

read -s -p "Enter a YubiKey OTP: " s 
if [ ! -d "$HOME/.yubico" ]; then
   mkdir $HOME/.yubico
fi
LEN=$(echo ${#s})
 
if [ $LEN -lt 44 ]; then
    if [ ! -f "$HOME/.yubico/authorized_yubikeys" ]; then
        echo 'The Yubikey is NOT active. Please contact with HPCNow! support'
    fi
    echo "The new Yubikey is NOT updated. Please contact with HPCNow! support"
else
    if [ ! -f "$HOME/.yubico/authorized_yubikeys" ]; then
        MSG="active"
    fi
    MSG="updated"
    echo "$USER:${s:0:12}" >> $HOME/.yubico/authorized_yubikeys
    chmod 700 $HOME/.yubico/
    chmod 600 $HOME/.yubico/authorized_yubikeys
fi
echo "
=======================================================================
    The 2-factor authentication based on Yubikey is now $MSG.

When login from SSH, juste activate your Yubikey after typing your
password, before typing enter.
If you have some problem with the authentication, please contact with
HPCNow! support <support@hpcnow.com>
=======================================================================
"
