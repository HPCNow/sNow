#!/bin/bash
########################################################################
# This is the sNow! Command Line Interface Continous Integration tests
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
# title:          sNow! Tools Continous Integration Tests
# author:         Jordi Blasco (HPCNow!)
# url:            http://www.hpcnow.com/snow
# description:    Performs integration tests on the sNow! Tools
# to run:         bash test/roles.sh
########################################################################
#set -xv 
echo --- sNow! Tools Integration Tests : roles ---
########## VARIABLES ##########
hostname="$(uname -n)"
branch="develop"
role=$1
hash="$(date +%s | sha256sum | base64 | head -c 15)" # randomized
SNOW_PATH=/sNow
SNOW_TOOL=${SNOW_PATH}/snow-tools
SNOW_DOMAINS=${SNOW_TOOL}/etc/domains.conf
self_active_domains=$(cat ${SNOW_DOMAINS} | grep -v ^# | gawk '{if($2 !~ /snow/){print $1}}')

if [[ ! -z "$role" ]]; then 
    self_active_domains=$(cat ${SNOW_DOMAINS} | grep -v ^# | gawk -v role=$role '{if($2 ~ role){print $1}}')
    echo "domains in the role $role :${self_active_domains}"
fi

echo hostname: ${hostname}
echo branch: ${branch}
echo role: ${role}
echo hash: ${hash}
########## AUTHENTICATION MICROSERVICE ##########
active_domains=$(snow list | egrep -v "Name|Domain-0" | wc -l)
if [[ "$active_domains" != "0" ]]; then 
    printf "It's not save to run the tests. Stopping domains...\n"
    domains=$(snow list | egrep -v "Name|Domain-0" | gawk '{print $1}')
    for domain in $domains; do 
        snow poweroff $domain
    done
fi

sleep 10

deployed_domains=$(snow list all | grep "Name:" | gawk '{print $2}')
if [[ ! -z "$deployed_domains" ]]; then 
    printf "It's not save to run the tests. Cleaning the system...\n"
    domains=$(snow list all | grep "Name:" | gawk '{print $2}')
    for domain in $domains; do 
        snow remove $domain 
    done
    printf "System ready to run the tests\n"
fi

for domain in ${self_active_domains}; do 
    if [[ -e /dev/snow_vg/${domain}-disk || -e /dev/snow_vg/${domain}-swap ]]; then
        lvremove -f /dev/snow_vg/${domain}-disk
        lvremove -f /dev/snow_vg/${domain}-swap
    fi
done

for domain in ${self_active_domains}; do
    echo "TEST: deploy ${domain}"
    snow deploy ${domain} | grep "OK" > /dev/null
    [ "$?" -ne 0 ] && printf "RESULT: fail\n\n" && exit 1
    printf "RESULT: pass\n\n"

    sleep 10

    echo "TEST: boot ${domain}"
    snow boot ${domain} &> /dev/null 
    [ "$?" -ne 0 ] && printf "RESULT: fail\n\n" && exit 1
    printf "RESULT: pass\n\n"

    sleep 10

    echo "TEST: test ${domain}"
    ssh ${domain} echo "OK" | grep "OK" > /dev/null
    [ "$?" -ne 0 ] && printf "RESULT: fail\n\n" && exit 1
    printf "RESULT: pass\n\n"

    sleep 10

    echo "TEST: destroy ${domain}"
    snow destroy ${domain} 
    [ "$?" -ne 0 ] && printf "RESULT: fail\n\n" && exit 1
    printf "RESULT: pass\n\n"

    sleep 10

    echo "TEST: deploy force  ${domain}"
    snow deploy ${domain} force | grep "OK" > /dev/null
    [ "$?" -ne 0 ] && printf "RESULT: fail\n\n" && exit 1
    printf "RESULT: pass\n\n"

    sleep 10

    echo "TEST: remove ${domain}"
    snow remove ${domain} 
    [ "$?" -ne 0 ] && printf "RESULT: fail\n\n" && exit 1
    printf "RESULT: pass\n\n"
done

