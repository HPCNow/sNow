#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

function error_exit()
{
    local e_msg="${1:-'Unknown Error: Please report the issue to https://bitbucket.org/hpcnow/snow-tools/issues'}"
    printf "\r\e[0K[\e[0;31m%c\e[m] %s \e[0;31m\e[m \n" "E" "${e_msg}" 1>&3
    sig=1
    exit 1
}

function msg()
{
    local msg="${1}"
    echo "${msg}" 1>&3
}

function error_msg()
{
    local e_msg="${1}"
    printf "\r\e[0K[\e[0;31m%c\e[m] %s \e[0;31m\e[m \n" "E" "${e_msg}" 1>&3
}

function warning_msg()
{
    local w_msg="${1}"
    printf "\r\e[0K[\e[0;38;5;208m%c\e[m] %s \e[0;32m\e[m \n" "W" "${w_msg}" 1>&3
}

function info_msg()
{
    local i_msg="${1}"
    printf "\r\e[0K[\e[0;32m%c\e[m] %s \e[0;32m\e[m \n" "I" "${i_msg}" 1>&3
}

function print_msg()
{
    local msg="${1}"
    echo $msg | tee /dev/fd/3
}

function logsetup()
{
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    chmod 600 $LOGFILE
    exec 3>&1 1>>${LOGFILE} 2>&1
}

function log()
{
    echo "[$(date)]: $*" 
}

function spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        if [[ "$sig" != "1" ]]; then
            printf "\r\e[0K[\e[0;32m%c\e[m] %s" "$spinstr" "${2}" 1>&3 
        fi
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
}

function error_check()
{
    local status=$1
    if [[ "$status" == "0" ]]; then
        printf "\r\e[0K[\e[0;32m%c\e[m] %s \e[0;32m%s\e[m \n" "*" "$2" "OK" 1>&3
    else
        printf "\r\e[0K[\e[0;31m%c\e[m] %s \e[0;31m%s\e[m \n" "!" "$2" "FAIL" 1>&3
    fi
}

function shelp()
{
    echo " 
    This is the sNow! Command Line Interface
    Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
    For more information, visit the official website : www.hpcnow.com

    Usage: snow [function] <option|domain|server>

    Function List:

        * init                                      | setup the system according to the parameters defined in snow.conf and active-domains.conf
        * config                                    | shows the sNow! configuration based on the changes applied in snow.conf and domains.conf
        * update tools                              | updates the sNow! Tools 
        * update configspace                        | updates configuration files from private git 
        * update template                           | updates the sNow! image used to create new domains
        * update firewall                           | updates the default sNow! firewall rules (only for sNow! with public IP address)
        * deploy <domain|server> <template> <force> | deploy specific domain/server (optional: with specific template or force to deploy existing domain/server) 
        * remove <domain>                           | removes an existing domain deployed with sNow!
        * list <all>                                | list current domains (services) and their status
        * boot <domain|server> <image>              | boot specific domain or server with optional image
        * boot domains                              | boot all the domains (all services not available under sNow! HA)
        * boot cluster <cluster> <image>            | boot all the compute nodes of the selected cluster (by default 20 nodes at once)
        * reboot <domain|server>                    | reboot specific domain or server
        * shutdown <domain|server>                  | shutdown specific domain or server
        * shutdown cluster <cluster>                | shutdown all the compute nodes of the selected cluster
        * destroy <domain|server>                   | force to stop specific domain or server
        * reset <domain|server>                     | force to reboot specific domain or server
        * poweroff <domain|server>                  | force to shutdown specific domain or server simulating a power button press
        * console <domain|server>                   | console access to specific domain or server
        * version                                   | shows the version of sNow!
        * help                                      | prints this message

    Examples:

        snow update tools
        snow deploy ldap01
    " 1>&3
}
#        * clone <server> <image>            | creates a PXE image to boot the compute nodes diskless

function end_msg()
{
    echo " 
    --------------------------------------------------------------------------

    ███████╗███╗   ██╗ ██████╗ ██╗    ██╗██╗
    ██╔════╝████╗  ██║██╔═══██╗██║    ██║██║
    ███████╗██╔██╗ ██║██║   ██║██║ █╗ ██║██║
    ╚════██║██║╚██╗██║██║   ██║██║███╗██║╚═╝
    ███████║██║ ╚████║╚██████╔╝╚███╔███╔╝██╗
    ╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝ ╚═╝
    Developed by HPCNow! www.hpcnow.com/snow

    Get enterprise features and end user enterprise support from HPCNow!
    Please help us to improve this project, report bugs and issues to : 
    sNow! Development <dev@hpcnow.com>
    If you found some error during the installation, please review the 
    log file : $LOGFILE
    Some changes may require to reboot the system. Please, consider to do it 
    before to move it into production.
    --------------------------------------------------------------------------
    " 1>&3
}

function config()
{
if [[ ! -f ${SNOW_DOMAINS} ]]; then
    error_msg "No ${SNOW_DOMAINS} found"
else
    cat ${SNOW_PATH}/snow-tools/etc/snow.conf 1>&3
    echo "==== Active Domains ====" 1>&3
    cat ${SNOW_PATH}/snow-tools/etc/active-domains.conf | grep -v "^#" |  gawk '{print $0}' 1>&3
fi
}

function download() 
{
    download_url=$1
    download_path=$2
    case $DOWNLD in
        axel) 
            axel -q -n 10 ${download_url} -o ${download_path} 
        ;;
        wget)
            wget -q -P ${download_path} ${download_url}
        ;;
        *) 
            error_exit "Error: $DOWNLD is not supported"
        ;;
    esac
} 1>>$LOGFILE 2>&1

function bkp()
{
    local bkpfile=$1
    local next=$(date +%Y%m%d%H%M)
    if [[ -e $bkpfile ]]; then 
        cp -pr $bkpfile $bkpfile.$next-snowbkp
    fi
}

function hex()
{
    #transforms the provided value to hexa
    printf "0x%X\n" $1;
}

function architecture_identification() 
{
    local cpudec=$(lscpu | grep "Model:" | gawk '{print $2}')
    local cpuhex=$(hex $cpudec)
    local architecture=$(grep $cpuhex ${SNOW_TOOL}/etc/cpu-id-map.conf | gawk '{print $2}')
    if [ -z $architecture ]; then
        warning_msg "Your CPU model is not recognised."
        warning_msg "Consider to extend the following file: ${SNOW_TOOL}/etc/cpu-id-map.conf"
    else
        export ARCHITECTURE=$architecture
    fi
} 1>>$LOGFILE 2>&1

function is_golden_node()
{
    # Returns 0 if this node is a golden node
    local gn=1
    for i in "${GOLDEN_NODES[@]}"; do 
        if [[ "$(hostname -s)" == "$i" ]]; then 
            local gn=0
        fi
    done
    return $gn
} 1>>$LOGFILE 2>&1

function get_os_distro()
{
    # OS release and Service pack discovery 
    local lsb_dist=$(lsb_release -si 2>&1 | tr '[:upper:]' '[:lower:]' | tr -d '[[:space:]]')
    local dist_version=$(lsb_release -sr 2>&1 | tr '[:upper:]' '[:lower:]' | tr -d '[[:space:]]')
    # Special case redhatenterpriseserver
    if [ "${lsb_dist}" = "redhatenterpriseserver" ]; then
        lsb_dist='redhat'
    fi
    if [ "${lsb_dist}" = "suselinux" ]; then
        lsb_dist='suse'
    fi
    if [[ -z "${lsb_dist}" ]]; then
        lsb_dist=$(uname -s)
    else
        export OSVERSION=${dist_version}
    fi
    export OS=$lsb_dist
}

function add_repo()
{
    local repo=$1
    case $OS in
        debian|ubuntu)
            wget -P /etc/apt/sources.list.d/ $repo
        ;;
        rhel|redhat|centos)
            yum-config-manager --add-repo $repo
        ;;
        suse|sle[sd]|opensuse)
            zypper --gpg-auto-import-keys ar $repo
        ;;
   esac
} 1>>$LOGFILE 2>&1

function add_repo_key()
{
    local repo_key=$1
    case $OS in
        debian|ubuntu)
            curl -sSL $repo_key | apt-key add - 
        ;;
        rhel|redhat|centos)
            rpm --import $repo_key
        ;;
   esac
} 1>>$LOGFILE 2>&1

function add_repos()
{
    local repos=$1
    for repo in $(cat $repos | gawk '{print $1}'); do
        if [[ ! -z $repo ]]; then
            add_repo $repo
        fi
    done
    for repo_key in $(cat $repos | gawk '{print $2}'); do
        if [[ ! -z ${repo_key} ]]; then
            add_repo_key ${repo_key}
        fi
    done
}


function install_software()
{
    local pkgs=$1
    case $OS in
        debian|ubuntu)
            INSTALLER="apt-get -y install"
            apt-get -y update
        ;;
        rhel|redhat|centos)
            INSTALLER="yum -y install"
        ;;
        suse|sle[sd]|opensuse)
            INSTALLER="zypper -n install"
        ;;
        *)
           error_exit "This distribution is not supported."
        ;;
   esac
   $INSTALLER $pkgs 
} 1>>$LOGFILE 2>&1


function prefix_to_bit_netmask() 
{
    local prefix=$1;
    local shift=$(( 32 - prefix ));
    local bitmask=""
    for (( i=0; i < 32; i++ )); do
        num=0
        if [ $i -lt $prefix ]; then
            num=1
        fi
        space=
        if [ $(( i % 8 )) -eq 0 ]; then
            space=" ";
        fi
        bitmask="${bitmask}${space}${num}"
    done
    echo $bitmask
}

function bit_netmask_to_wildcard_netmask()
{
    local bitmask=$1;
    local wildcard_mask=
    for octet in $bitmask; do
        wildcard_mask="${wildcard_mask} $(( 255 - 2#$octet ))"
    done
    echo $wildcard_mask;
}

function mask2cidr()
{
    local nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) error_exit "Error: $dec is not recognised"
        esac
    done
    echo "$nbits"
}

function generate_hostlist()
{
    local ip=$1
    local host_extension=$2
    local net=$(echo $ip | cut -d '/' -f 1);
    local prefix=$(echo $ip | cut -d '/' -f 2);
    if [[ $prefix =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        cidr=$(mask2cidr $prefix)
    else
        cidr=$prefix
    fi
    local bit_netmask=$(prefix_to_bit_netmask $cidr);
    local wildcard_mask=$(bit_netmask_to_wildcard_netmask "$bit_netmask");
    local str=
    for (( i = 1; i <= 4; i++ )); do
        range=$(echo $net | cut -d '.' -f $i)
        mask_octet=$(echo $wildcard_mask | cut -d ' ' -f $i)
        if [ $mask_octet -gt 0 ]; then
            range="{$range..$(( $range | $mask_octet ))}";
        fi
        str="${str} $range"
    done
    local ips=$(echo $str | sed "s, ,\\.,g"); 
    local hostip=( $(eval echo $ips | tr ' ' '\n') )
    if (( "${#host[@]}" > "${#hostip[@]}" )); then
        error_exit "The /etc/hosts can NOT be generated because the IP rank is too short! ($ip/$cidr)"
    fi
    for (( i=0; i<${#host[@]}; i++ ));
    do 
        printf "%s  \t  %s\n" "${hostip[$i]}" "${host[$i]}$host_extension"
    done
}


function init()
{
    # Check for snow.conf
    if [[ -f ${SNOW_CONF}/system_files/etc/snow.conf ]]; then
        ln -s ${SNOW_CONF}/system_files/etc/snow.conf ${SNOW_TOOL}/etc/snow.conf
    elif [[ -f ${SNOW_TOOL}/etc/snow.conf ]]; then
        mv ${SNOW_TOOL}/etc/snow.conf ${SNOW_CONF}/system_files/etc/snow.conf
        ln -s ${SNOW_CONF}/system_files/etc/snow.conf ${SNOW_TOOL}/etc/snow.conf
    else
        error_exit "The snow.conf is not yet available."
    fi
    # Check for active-domains.conf 
    if [[ -f ${SNOW_CONF}/system_files/etc/active-domains.conf ]]; then
        ln -s ${SNOW_CONF}/system_files/etc/active-domains.conf ${SNOW_TOOL}/etc/active-domains.conf
    elif [[ -f ${SNOW_TOOL}/etc/active-domains.conf ]]; then
        mv ${SNOW_TOOL}/etc/active-domains.conf ${SNOW_CONF}/system_files/etc/active-domains.conf
        ln -s ${SNOW_CONF}/system_files/etc/active-domains.conf ${SNOW_TOOL}/etc/active-domains.conf
    else
        error_exit "The active-domains.conf is not yet available."
    fi

    if (! ${HA_NFSROOT}) ; then
        # NFS_ROOT Exports
        if [[ ! -d /etc/exports.d ]]; then
           mkdir -p /etc/exports.d
        fi
        if [[ ! -f ${SNOW_CONF}/system_files/etc/exports.d/snow_domains.exports ]]; then
            if [[ ! -d ${SNOW_CONF}/system_files/etc/exports.d ]]; then
                mkdir -p ${SNOW_CONF}/system_files/etc/exports.d
            fi
            snow_servers_exports=$(echo "${SNOWNODES[*]}(rw,sync,no_subtree_check,no_root_squash)" | sed 's/ /(rw,sync,no_subtree_check,no_root_squash) /g')
            gawk -v snow_servers_exports=$snow_servers_exports '{
                if ($1 !~ /^#|snow/){
                    print "/sNow/"$1"\t "snow_servers_exports" "$1"(rw,sync,no_subtree_check,no_root_squash)"
                }
            }' ${SNOW_ACTIVE_DOMAINS} > ${SNOW_CONF}/system_files/etc/exports.d/snow_domains.exports
            ln -sf ${SNOW_CONF}/system_files/etc/exports.d/snow_domains.exports /etc/exports.d/snow_domains.exports
            warning_msg "Review the following exports file : ${SNOW_CONF}/system_files/etc/exports.d/snow_domains.exports"
            warning_msg "Once you are done, execute exportfs -u"
        fi
    fi
    #If the master is the NFS Server it will setup the ${SNOW_CONF}/system_files/etc/exports.d/snow.exports
    if [[ "$(uname -n)" == "${NFS_SERVER}" ]]; then
        if [[ ! -f ${SNOW_CONF}/system_files/etc/exports.d/snow.exports ]]; then 
            if [[ ! -d ${SNOW_CONF}/system_files/etc/exports.d ]]; then
                mkdir -p ${SNOW_CONF}/system_files/etc/exports.d
            fi
            echo "/sNow            ${NET_SNOW[2]}0/${NET_SNOW[3]}(rw,sync,no_subtree_check,no_root_squash)" >> ${SNOW_CONF}/system_files/etc/exports.d/snow.exports
            warning_msg "Review the following exports file : ${SNOW_CONF}/system_files/etc/exports.d/snow.exports"
            warning_msg "Once you are done, execute exportfs -rv"
        fi
        if [[ ! -d /etc/exports.d ]]; then
            mkdir -p /etc/exports.d
        fi
        ln -sf ${SNOW_CONF}/system_files/etc/exports.d/snow.exports /etc/exports.d/snow.exports
    fi
    # sNow! Domains configuration table
    if [[ ! -f ${SNOW_CONF}/system_files/etc/domains.conf ]]; then
        ln -s ${SNOW_CONF}/system_files/etc/domains.conf ${SNOW_TOOL}/etc/domains.conf
    fi
    if [[ ! -e ${SNOW_TOOL}/etc/domains.conf ]]; then
        cat ${SNOW_TOOL}/etc/domains.conf-example > ${SNOW_TOOL}/etc/domains.conf
        if [[ ! -z ${NET_DMZ[0]} ]]; then
            gawk -v brdmz=${NET_DMZ[0]} -v gwdmz=${NET_DMZ[1]} -v netdmz=${NET_DMZ[2]} -v maskdmz=${NET_DMZ[3]} \
                 -v brsnow=${NET_SNOW[0]} -v gwsnow=${NET_SNOW[1]} -v netsnow=${NET_SNOW[2]} -v masksnow=${NET_SNOW[3]} \
                'BEGIN{i=0}{
                    if ($1 !~ /^#/){
                        i=i+1
                        printf "%12s\t %20s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s \n", $1, $2, "eth0", netsnow""i, brsnow, i, "01", masksnow, gwsnow, "eth1", netdmz""i, brdmz, i, "02", maskdmz, gwdmz  
                    }
                }' ${SNOW_ACTIVE_DOMAINS} >> ${SNOW_CONF}/system_files/etc/domains.conf
        else
            gawk -v brpub=${NET_PUB[0]} -v gwpub=${NET_PUB[1]} -v netpub=none -v maskpub=${NET_PUB[3]} \
                 -v brsnow=${NET_SNOW[0]} -v gwsnow=${NET_SNOW[1]} -v netsnow=${NET_SNOW[2]} -v masksnow=${NET_SNOW[3]} \
                'BEGIN{i=0}{
                    if ($1 !~ /^#/){
                        i=i+1
                        printf "%12s\t %20s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s \n", $1, $2, "eth0", netsnow""i, brsnow, i, "01", masksnow, gwsnow, "eth1", netpub, brpub, i, "02", maskpub, gwpub  
                    }
                }' ${SNOW_ACTIVE_DOMAINS} >> ${SNOW_CONF}/system_files/etc/domains.conf
        fi
        ln -s ${SNOW_CONF}/system_files/etc/domains.conf ${SNOW_TOOL}/etc/domains.conf
        warning_msg "Review the domains config file : ${SNOW_TOOL}/etc/domains.conf"
    fi
    # Generate /etc/hosts based on the sNow! domains and compute node list defined in snow.conf (parameter CLUSTERS)
    host=( )
    for i in "${!CLUSTERS[@]}"
    do 
        node_rank ${CLUSTERS[$i]}
        host+=( $(eval echo "$NPREFIX{${NRANK[0]}..${NRANK[1]}}") )
    done
    bkp /etc/hosts
    generate_hostlist ${NET_SNOW[2]}100/${NET_SNOW[3]} "${NET_SNOW[4]}" >> /etc/hosts
    generate_hostlist ${NET_MGMT[2]}100/${NET_MGMT[3]} "${NET_MGMT[4]}" >> /etc/hosts
    generate_hostlist ${NET_LLF[2]}100/${NET_LLF[3]} "${NET_LLF[4]}" >> /etc/hosts
    cp -p /etc/hosts ${SNOW_CONF}/system_files/etc/hosts 

    # Generate /etc/ssh/ssh_known_hosts
    bkp /etc/ssh/ssh_known_hosts
    echo "$(echo ${host[*]} | sed 's/ /,/g') $(cat /etc/ssh/ssh_host_rsa_key.pub)" > /etc/ssh/ssh_known_hosts
    cp -p /etc/ssh/ssh_known_hosts ${SNOW_CONF}/system_files/etc/ssh/ssh_known_hosts
    # Generate /etc/ssh/shosts.equiv
    bkp /etc/ssh/shosts.equiv
    echo ${host[*]} | tr " " "\n" | sed 's/^/+/g' > /etc/ssh/shosts.equiv
    cp -p /etc/ssh/shosts.equiv ${SNOW_CONF}/system_files/etc/ssh/shosts.equiv
    bkp /root/.shosts
    cp /etc/ssh/shosts.equiv /root/.shosts
    # Update /etc/ssh/ssh_config
    bkp /etc/ssh/ssh_config
    if [[ ! $(grep -q "HostbasedAuthentication yes" /etc/ssh/ssh_config) ]]; then
        echo "    HostbasedAuthentication yes" >> /etc/ssh/ssh_config
        echo "    GlobalKnownHostsFile /etc/ssh/ssh_known_hosts" >> /etc/ssh/ssh_config
        echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
    fi
} 1>>$LOGFILE 2>&1

function update_tools()
{
if [[ ! -d ${SNOW_TOOL} ]]; then
    mkdir -p ${SNOW_TOOL}
    cd ${SNOW_TOOL}
    git clone http://bitbucket.org/hpcnow/snow-tools.git || error_exit "ERROR: please review the SSH certificates in your bitbucket."
    cd -
else
    cd ${SNOW_TOOL}
    git pull http://bitbucket.org/hpcnow/snow-tools.git || error_exit "ERROR: please review the SSH certificates in your bitbucket."
fi 
} 1>>$LOGFILE 2>&1

function update_configspace()
{
if [[ ! -d ${SNOW_CONF}  ]]; then
    mkdir -p ${SNOW_CONF}
    cd ${SNOW_CONF}
    git clone http://bitbucket.org/hpcnow/snow-configspace.git || error_exit "ERROR: please review the SSH certificates in your bitbucket."
    cd -
else
    if [[ -z "$TOKEN" || -z "$PRIVATE_REPO" ]]; then
        error_exit "ERROR: your private git repo and token are not defined. sNow! is not able to update without these two parameters."
        exit 1
    fi
    cd ${SNOW_CONF}
    git pull https://$TOKEN:x-oauth-basic@$PRIVATE_REPO || error_exit "ERROR: please review the SSH certificates in your bitbucket."
fi
} 1>>$LOGFILE 2>&1

function update_firewall()
{
    pub_nic=${NET_PUB[0]}
    pub_mac=$(ip -f link addr show ${pub_nic} | gawk '{if($0 ~ /ether/){print $2}}')
    if [[ -z $pub_mac ]]; then
        error_exit "Your system do not have public network, so the firewall can not be setup"
    else
        bkp /etc/ufw/before.rules
        if [[ ! -e /etc/ufw/before.rules.orig ]]; then
            cp -p /etc/ufw/before.rules /etc/ufw/before.rules.orig
            systemctl enable ufw
        fi
        # Include the first part of the original rules files
        gawk 'BEGIN{dump=1}
            {
                if($0 ~ /#   ufw-before-forward/){
                    dump=0
                }
                if(dump == "1"){
                    print $0
                }
            }' /etc/ufw/before.rules.orig > /etc/ufw/before.rules
        sed -i "s|DEFAULT_FORWARD_POLICY=\"DROP\"|DEFAULT_FORWARD_POLICY=\"ACCEPT\"|g" /etc/default/ufw
        sed -i "s|#net/ipv4/ip_forward=1|net/ipv4/ip_forward=1|g" /etc/ufw/sysctl.conf
        echo "*nat\n:PREROUTING ACCEPT [0:0]\n:POSTROUTING ACCEPT [0:0]" >> /etc/ufw/before.rules

        # Apply DNAT rules defined per role in $SNOW_TOOLS/etc/dmz_portmap.conf
        gawk -v pub_nic=${pub_nic} 'FNR==NR{
            if($0 !~ /^#/){
                if($2 ~ /,/){
                    n=split($2,a,",")
                    for (i =0; ++i <=n;){
                        role=a[i]
                        ip[role]=$10
                    }
                }
                else{
                    ip[$2]=$10
                }
            }
            next
        }
        {
            if($0 !~ /^#/){
                if(ip[$4] != ""){
                printf "-A PREROUTING -p "$1" -i "pub_nic" --dport "$2" -j DNAT --to "ip[$4]":"$3"\n"
                }
            }
        }' $SNOW_TOOL/etc/domains.conf $SNOW_TOOL/etc/dmz_portmap.conf >> /etc/ufw/before.rules

        # Add gateway rules
        echo "-A POSTROUTING -s ${NET_SNOW[2]}/${NET_SNOW[3]} -d ${NET_SNOW[2]}/${NET_SNOW[3]} -j ACCEPT" >> /etc/ufw/before.rules
        echo "-A POSTROUTING -s ${NET_SNOW[2]}/${NET_SNOW[3]} -o ${pub_nic} -j MASQUERADE" >> /etc/ufw/before.rules
        echo "COMMIT" >> /etc/ufw/before.rules

        # Include the rest of the rules in the original file
        gawk '
        BEGIN{dump=0}
        {
            if($0 ~ /#   ufw-before-forward/){
                dump=1
            }
            if(dump == "1"){
                print $0
            }
        }' /etc/ufw/before.rules.orig >> /etc/ufw/before.rules

        # Open the ports related with deployed sNow! services
        gawk 'BEGIN{
            print "[sNow]\ntitle=sNow Services\ndescription=sNow Services"
            ports["tcp"]=""
            ports["udp"]=""
        }
        {
            if($0 !~ /^#/){
                ports[$1]=ports[$1]","$2
            }
        }
        END{
            if(ports["udp"] != ""){
                ports["udp"]=ports["udp"]"/udp"
            }
            if(ports["tcp"] != ""){
                ports["tcp"]="22"ports["tcp"]"/tcp"
            }
            print "ports="ports["tcp"] ports["udp"]
        }' $SNOW_TOOL/etc/dmz_portmap.conf > /etc/ufw/applications.d/ufw-snow

        ufw allow sNow
        #ufw disable
        #ufw --force enable
    fi
}

function update_xen_image()
{
if [[ ! -d ${SNOW_PATH}/domains/template ]]; then
    mkdir -p ${SNOW_PATH}/domains/template
    wget http://snow.hpcnow.com/snow-template.md5sum -P ${SNOW_PATH}/domains/template || error_exit "ERROR: the image can not be downloaded. Please check your network setup."
    wget http://snow.hpcnow.com/snow-template.tar.bz2 -P ${SNOW_PATH}/domains/template || error_exit "ERROR: the image can not be downloaded. Please check your network setup."
else
    if [[ -f ${SNOW_PATH}/domains/template/snow-template.tar.bz2 ]]; then
        MD5LOCAL=$(md5sum ${SNOW_PATH}/domains/template/snow-template.tar.bz2 | gawk '{ print $1 }')
        wget http://snow.hpcnow.com/snow-template.md5sum -P ${SNOW_PATH}/domains/template || error_exit "ERROR: the image can not be downloaded. Please check your network setup."
        MD5HPCNOW=$(cat ${SNOW_PATH}/domains/template/snow-template.md5sum | gawk '{ print $1 }')
        if [[ "$MD5LOCAL" != "$MD5HPCNOW" ]]; then
            info_msg "Downloading most recent sNow! domain template"
            wget http://snow.hpcnow.com/snow-template.tar.bz2 -P ${SNOW_PATH}/domains/template || error_exit "ERROR: the image can not be downloaded. Please check your network setup."
        else
            info_msg "sNow domain template is up-to-date."
        fi
    else
        wget http://snow.hpcnow.com/snow-template.tar.bz2 -P ${SNOW_PATH}/domains/template || error_exit "ERROR: the image can not be downloaded. Please check your network setup."
    fi
fi 
} 1>>$LOGFILE 2>&1

function xen_create()
{
    get_server_distribution $1 
    if [[ -f ${SNOW_PATH}/snow-tools/etc/domains/$1.cfg ]]; then
        if [[ "$opt3" != "force" ]]; then
            error_exit "The domain $1 already exist, please use 'force' option to overwrite the domain or remove it first with : snow remove $1."
        else
            warning_msg "The domain $1 will be installed and all the data contained in this domain will be removed."
            xen_delete $1
            FORCE="--force"
        fi
    else
        if (($IS_VM)) ; then
            info_msg "Deploying the domain $1. It can take few minutes. Please wait!"
        else
            error_exit "The domain $1 is NOT available in the ${SNOW_DOMAINS}."
        fi
    fi

    if [[ -n "$IMG_DST" ]]; then
        IMG_DST_OPT="--${IMG_DST}"
    fi 
    cat ${SNOW_DOMAINS} | grep "$opt2" | gawk -v force="$FORCE" -v img_dst="$IMG_DST_OPT" -v pwd="$MASTERPWD" '{
        hostname=$1; role=$2; dev_nic1=$3; ip_nic1=$4; bridge_nic1=$5; mac_nic1=$6; mask_nic1=$7; gw_nic1=$8
        }
        END{
        system("xen-create-image --config=/sNow/snow-tools/etc/xen-tools.conf --roledir=/sNow/snow-tools/etc/role.d --hostname="hostname" --mac="mac_nic1" --bridge="bridge_nic1" --ip="ip_nic1" --gateway="gw_nic1" --netmask="mask_nic1" --role=snow,"role" --copyhosts --password=\""pwd"\" "force" "img_dst)
        }' 
    if [[ ! -f ${SNOW_PATH}/snow-tools/etc/domains/$1.cfg ]]; then
        error_exit "Unable to install the domain, please report the issue to HPCNow!"
        error_check 1 "Deployment of $1 Failed."
    else
        second_nic=$(gawk -v guest=$opt2 '{if($1 == guest){print $10}}' ${SNOW_DOMAINS}) 
        if [[ "$second_nic" != "none" && -e ${SNOW_TOOL}/etc/domains/$opt2.cfg ]]; then 
            guest_network=$(gawk -v guest=$opt2 '{if($1 == guest){print "vif        = [ '\''ip="$4", mac="$6", bridge="$5"'\'', '\''ip="$10", mac="$12", bridge="$11"'\'' ]"}}' ${SNOW_DOMAINS})
            gawk -v gnet="$guest_network" '{if($1 == "vif"){print gnet}else{print $0}}' ${SNOW_TOOL}/etc/domains/$opt2.cfg > ${SNOW_TOOL}/etc/domains/$opt2.cfg.extended
            mv ${SNOW_TOOL}/etc/domains/$opt2.cfg.extended ${SNOW_TOOL}/etc/domains/$opt2.cfg
        fi
        error_check 0 "Deployment of $1 completed."
    fi
} 1>>$LOGFILE 2>&1

function xen_delete()
{
    get_server_distribution $1 
    if [[ ! -f ${SNOW_PATH}/snow-tools/etc/domains/$1.cfg ]]; then
        error_msg "There is no domain with this name. Please, review the name of the domain to be removed."
    else
        if [[ -n "$IMG_DST" ]]; then
            IMG_DST_OPT="--${IMG_DST}"
        fi 
        xen-delete-image $IMG_DST_OPT --hostname=$1
        rm -f ${SNOW_PATH}/snow-tools/etc/domains/$1.cfg
    fi
} 1>>$LOGFILE 2>&1

function create_base()
{
    if [[ "$opt3" == "force" ]]; then
        FORCE="--force"
    fi 
    xen_create deploy
}

function node_rank()
{
    if [[ $1 =~ \] ]]; then
        NPREFIX=$(echo $1 | cut -d[ -f1)
        NRANK=($(echo $1 | cut -d[ -f2| cut -d] -f1|  sed -e "s/-/ /"))
        NLENG=$(echo ${NRANK[1]}-${NRANK[0]} | bc -l)
    else 
        NLENG=0
    fi
}

function boot_copy()
{
    local pxelinux_cfg=$1
    for i in $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
    do 
        cp -p ${pxelinux_cfg} ${SNOW_CONF}/boot/pxelinux.cfg/$(gethostip $NPREFIX$i | gawk '{print $3}')
    done
}

function list_templates()
{
    local templates_path=${SNOW_CONF}/boot/templates
    local templates_avail=$(ls -1 ${templates_path}//*/*.pxe | sed -e "s|${templates_path}||g" | cut -d"/" -f1)
    for template in ${templates_avail}; do
        local template_desc=${templates_path}/${template}/${template}.desc
        print_msg "$template"
        cat ${template_desc} | tee /dev/fd/3
    done
}

function deploy()
{
    if [[ -z "$1" ]]; then
        error_exit "ERROR: No domain or node to deploy"
    fi
    get_server_distribution $1
    if (($IS_VM)) ; then
        xen_create $1 $2
    else
        if [[ -z "$opt4" ]]; then
            if [[ -z "$opt3" ]]; then
                local template=${DEFAULT_TEMPLATE}
                warning_msg "sNow! will start to deploy the following node(s) $1 in 10 seconds, unless you interrupt that with 'Ctrl+C'. Use 'force' option to avoid the waiting."
                sleep 10
            elif [[ "$opt3" == "force"  ]]; then
                local template=${DEFAULT_TEMPLATE}
                warning_msg "The node(s) $1 will be installed and all the data located in the local file system will be removed."
            #elif [[ "$opt3" != "force"  ]]; then
            else
                local template=$opt3
                warning_msg "sNow! will start to deploy the following node(s) $1 in 10 seconds, unless you interrupt that with 'Ctrl+C'. Use 'force' option to avoid the waiting."
                sleep 10
            fi
        else
            if [[ "$opt4" == "force" ]]; then
                local template=$opt3
                warning_msg "The node(s) $1 will be deployed with $template template. All the data located in the local file system will be removed."
            else
                error_exit "sNow! deploy only supports the following options: snow deploy <domain|server> <template> <force>"
            fi
        fi
        node_rank $1
        #BLOCKN=${2:-$BLOCKN}
        #BLOCKD=${3:-$BLOCKD}
        #local template=${2:-$DEFAULT_TEMPLATE}
        local template_pxe=${SNOW_CONF}/boot/templates/${template}/${template}.pxe
        local default_boot_pxe=${SNOW_CONF}/boot/images/${DEFAULT_BOOT}/${DEFAULT_BOOT}.pxe
        if ! [[ -f ${template_pxe} ]] ; then
            error_exit "No template $template available in ${SNOW_CONF}/boot/templates/"
        fi
        if (( $NLENG > 0 )); then
            info_msg "Booting node range $1 for deployment... This will take a while, Please wait."
            #parallel -j $BLOCKN snow check_host_status "$NPREFIX{}${NET_MGMT[4]}" ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
            boot_copy ${template_pxe}
            parallel -j $BLOCKN \
            info_msg "Booting node : $NPREFIX{} ... Please wait" \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMIUSER -P $IPMIPWD power reset \; \
            sleep 5 \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMIUSER -P $IPMIPWD power on \; \
            sleep $BLOCKD \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
            sleep $BOOT_DELAY
            info_msg "You can monitor the deployment with : snow console <compute-node-name>"
            #info_msg "Setting up default boot device... Please wait"
            boot_copy ${default_boot_pxe}
            error_check 0 "Deployment started."
        else
            check_host_status $1${NET_MGMT[4]}
            info_msg "Booting node range $1 for deployment... This will take a while, Please wait."
            cp -p ${template_pxe} ${SNOW_CONF}/boot/pxelinux.cfg/$(gethostip $1 | gawk '{print $3}')
            ipmitool -I $IPMITYPE -H $1${NET_MGMT[4]} -U $IPMIUSER -P $IPMIPWD power reset
            sleep 5
            ipmitool -I $IPMITYPE -H $1${NET_MGMT[4]} -U $IPMIUSER -P $IPMIPWD power on
            info_msg "Deploying node : $1 ... Please wait"
            sleep $BOOT_DELAY
            info_msg "You can monitor the deployment with : snow console $1"
            cp -p ${default_boot_pxe} ${SNOW_CONF}/boot/pxelinux.cfg/$(gethostip $1 | gawk '{print $3}') 
            error_check 0 "Deployment started."
        fi
    fi
}  1>>$LOGFILE 2>&1

function patch_network_configuration()
{
    case $OS in
        debian|ubuntu)
            echo "Nothing required"
        ;;
        rhel|redhat|centos)
            gawk '{if($1 ~ /^HOSTNAME/){print "HOSTNAME="}else{print $0}}' /etc/sysconfig/network > ${mount_point}/etc/sysconfig/network
            for i in $(ls -1 /etc/sysconfig/network-scripts/ifcfg-*)
            do
                gawk '{if($1 ~ /^HWADDR/){print "HWADDR="}else{print $0}}' $i > ${mount_point}/$i
            done
       ;;
       suse|sle[sd]|opensuse)
            echo "Nothing required since using kiwi"
       ;;
   esac
}

function generate_pxe_image()
{
    IMAGE=$1
    case $OS in
        debian|ubuntu)
            cp -p /boot/initrd.img-$(uname -r) ${SNOW_CONF}/boot/images/$IMAGE/
            cp -p /boot/vmlinuz-$(uname -r) ${SNOW_CONF}/boot/images/$IMAGE/
            generate_rootfs $IMAGE
        ;;
        rhel|redhat|centos)
            dracut -a "nfs network base" --host-only -f ${SNOW_CONF}/boot/images/$IMAGE/initrd-$(uname -r).img $(uname -r) root=dhcp 
            cp -p /boot/vmlinuz-$(uname -r) ${SNOW_CONF}/boot/images/$IMAGE/
            generate_rootfs $IMAGE
       ;;
       suse|sle[sd]|opensuse)
           kiwi --root / --add-profile netboot --type pxe -d ${SNOW_CONF}/boot/images/$IMAGE
           mv initrd-netboot-*.gz initrd-$(uname -r)
           mv initrd-netboot-*.kernel linux-$(uname -r)
           mv *x86_64* root.gz
       ;;
   esac
}

function hooks()
{
    local hooks_path=$1
    local hooks=$(ls -1 ${hooks_path}/??-*.sh)
    if [[ ! -z $hooks ]]; then
        for hook in $hooks
        do
            if [[ -x "$hook" ]]; then
                $hook && error_check 0 "Running hook : $hook " || error_check 1 "Running hook error : $hook " &
                spinner $!             "Running hook : $hook "
            else
                warning_msg "File '$hook' is not executable. If you want to run it, do : chmod 750 $hook"
            fi
        done
    fi
} 

function first_boot_hooks()
{
    hooks_path=$1
    cp -p ${hooks_path}/first_boot/first_boot.service  /lib/systemd/system/
    cp -p ${hooks_path}/first_boot/first_boot /usr/local/bin/first_boot
    chmod 700 /usr/local/bin/first_boot
    systemctl enable first_boot
} 1>>$LOGFILE 2>&1

function generate_rootfs()
{
    # path to the PXE config file
    local image_pxe=${SNOW_CONF}/boot/images/${image}/${image}.pxe
    # rootfs size in megabytes
    local rootfs_size="4096"
    # set mount point for the rootfs
    local mount_point="rootfs-loop"
    # create a rootfs file
    dd if=/dev/zero of=rootfs bs=1k count=$(($rootfs_size * 1024))
    # create an ext3 file system
    mkfs.ext3 -m0 -F -L root rootfs
    # create a mount point
    mkdir -p ${mount_point}
    # mount the newly created file system
    mount -t ext3 -o loop rootfs ${mount_point}
    # Create required directory structure
    mkdir -p ${mount_point}/{bin,boot,dev,etc,home,lib64,mnt,proc,root/.ssh,sbin,sys,usr,var/{lib,log,run,tmp},var/lib/nfs,tmp,var/run/netreport,var/lock/subsys}
    # Transfer required files
    cd ${mount_point} 
    cp -ap /etc .
    cp -ap /dev .
    cp -ap /bin .
    cp -ap /sbin .
    cp -ap /lib .
    cp -ap /lib64 .
    cp -ap /var/lib/nfs var/lib
    cp -ap /usr .
    cp -ap /root/.bashrc root/
    cp -ap /root/.bash_profile root/
    cp -ap /root/.bash_logout root/
    cp -ap /root/.ssh root/
    # set required permissions
    chown root:lock var/lock
    # cd out of the mount point
    cd ..
    # Update fstab
    bkp ${mount_point}/etc/fstab
    cp -p ${mount_point}/etc/fstab ${mount_point}/etc/fstab.orig
    gawk '{
        if($2 == "/"){
            print "/dev/ram0               /              ext3    defaults        0 0"
        }
        else{
            print $0
        }
    }' ${mount_point}/etc/fstab.orig > ${mount_point}/etc/fstab
    rm ${mount_point}/etc/fstab.orig
    # hooks: 
    hooks ${SNOW_CONF}/boot/images/$image
    first_boot_hooks ${SNOW_CONF}/boot/images/$image
    # * if local scratch disk /tmp
    patch_network_configuration

    umount ${mount_point}
    gzip -c rootfs | dd of=${SNOW_CONF}/boot/images/$image/rootfs.gz
    # create PXE boot configuration
    sed -e "s|__IMAGE__|$image|" ${SNOW_TOOL}/etc/config_template.d/boot/pxelinux.cfg/diskless > ${image_pxe}
}

function clone()
{
    local node=$1
    local image=$2
    if [[ -z "$node" ]]; then
        error_exit "ERROR: no node name to clone is provided"
    fi
    if [[ -z "$image" ]]; then
        error_exit "ERROR: no name is provided for the image"
    fi
    # Check if snow CLI is executed in the same golden node or from the snow server
    if [[ "$(uname -n)" == "$node" ]]; then
        if [[ -f ${SNOW_CONF}/boot/images/$image/rootfs.gz ]]; then
            warning_msg "This will overwrite the image $image"
        else
            warning_msg "This will clone $node and generate the image $image."
        fi
        get_server_distribution $node
        check_host_status ${node}${NET_MGMT[4]}
        generate_pxe_image $image
    else
        ssh $node $0 clone $@
    fi
}

function list()
{
    xl list $opt2 | tee /dev/fd/3
}

function avail_domains()
{
    LC_ALL=C xen-list-images --test /sNow/snow-tools/etc/domains | tee /dev/fd/3
}

function check_host_status()
{
    PING=$(ping -c 1 $1 &> /dev/null)
    if [[ "$?" != "0" ]]; then
        error_exit "The host $1 is not responsive. Please check the host name, DNS server or /etc/hosts."
    fi 
}

function boot()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No domain or node to boot."
    fi
    IMAGE=$2
    get_server_distribution $1
    if (($IS_VM)) ; then
        if [[ -f ${SNOW_PATH}/snow-tools/etc/domains/${1}${DOM_EXT}.cfg ]]; then 
            IS_UP=$(xl list $1)
            if [[ "$IS_UP" == "" ]]; then 
                sleep 1
                xl create ${SNOW_PATH}/snow-tools/etc/domains/${1}${DOM_EXT}.cfg
            else
                warning_msg "The domain $1 is already runnning"
            fi
        else
            error_exit "The domain $1 needs to be deployed first: Execute : snow deploy $1"
        fi
    else
        node_rank $1
        BLOCKN=${2:-$BLOCKN}
        BLOCKD=${3:-$BLOCKD}
        if [ -z "$IMAGE" ]; then
            boot_copy $DEFAULT_BOOT
        else
            boot_copy $IMAGE
        fi
        if (( $NLENG > 1 )); then
            parallel -j $BLOCKN \
            echo "$NPREFIX{}${NET_MGMT[4]}" \; \
            sleep $BLOCKD \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMIUSER -P $IPMIPWD power on \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else 
            check_host_status $1${NET_MGMT[4]}
            ipmitool -I $IPMITYPE -H $1${NET_MGMT[4]} -U $IPMIUSER -P $IPMIPWD power on
        fi
    fi
}

function get_server_distribution()
{
    node_rank $1
    if (( $NLENG > 0 )); then
        # VM ranks are not yet supported
        IS_VM=0
    else
        IS_VM=$(cat ${SNOW_DOMAINS} | gawk -v vm="$1" 'BEGIN{isvm=0}{if($1 == vm){isvm=1}}END{print isvm}')
    fi
}

function boot_domains()
{
    for i in ${SELF_ACTIVE_DOMAINS}
    do 
        boot $i
    done
}

function boot_cluster()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No cluster to boot."
    fi
    CLUSTERNAME=$1
    BLOCKN=${2:-$BLOCKN}
    BLOCKD=${3:-$BLOCKD}
    # In order to avoid power consumption peaks, the nodes needs to be booted in a blocks of few nodes with a delayed (5 seconds) timing between blocks 
    # BlockN is the number of nodes to be iniciated at the same time (default should be 5)
    # BlockD is the delay between one block and the following one (default 5 seconds)
    # GNU Parallel : Pass $BLOCKN + Sleep $BLOCKD
    boot ${CLUSTERS[$1]} 
}

function ncmd()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No domain(s) or node(s) to execute command."
    fi
    pdsh -w $1 $2 $3 $4
}

function nreboot()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No domain(s) or node(s) to reboot."
    fi
    pdsh -w $1 reboot
}  &>/dev/null

function nshutdown()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No domain(s) or node(s) to shutdown."
    fi
    pdsh -w $1 systemctl poweroff
}  &>/dev/null

function shutdown_domains()
{
    for i in ${SELF_ACTIVE_DOMAINS}
    do 
        nshutdown $i
    done
}

function shutdown_cluster()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No cluster to shutdown."
    fi
    CLUSTERNAME=$1
    nshutdown ${CLUSTERS[$1]} 
}  &>/dev/null

function ndestroy()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No domain(s) or node(s) to power down."
    fi
    get_server_distribution $1
    if (($IS_VM)) ; then
        xl destroy $1
    else
        node_rank $1
        BLOCKN=${2:-$BLOCKN}
        BLOCKD=${3:-$BLOCKD}
        if (( $NLENG > 1 )); then
            parallel -j $BLOCKN \
            echo "$NPREFIX{}${NET_MGMT[4]}" \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMIUSER -P $IPMIPWD power off \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_MGMT[4]}
            ipmitool -I $IPMITYPE -H $1${NET_MGMT[4]} -U $IPMIUSER -P $IPMIPWD power off
        fi
    fi
}

function npoweroff()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No domain(s) or node(s) to shutdown."
    fi
    get_server_distribution $1
    if (($IS_VM)) ; then
        xl shutdown $1
    else
        node_rank $1
        BLOCKN=${2:-$BLOCKN}
        BLOCKD=${3:-$BLOCKD}
        if (( $NLENG > 1 )); then
            parallel -j $BLOCKN \
            echo "$NPREFIX{}${NET_MGMT[4]}" \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMIUSER -P $IPMIPWD power soft \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_MGMT[4]}
            ipmitool -I $IPMITYPE -H $1${NET_MGMT[4]} -U $IPMIUSER -P $IPMIPWD power soft
        fi
    fi
}

function poweroff_domains()
{
    for i in ${SELF_ACTIVE_DOMAINS}
    do 
        npoweroff $i
    done
}

function nreset()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: No domain(s) or node(s) to reset."
    fi
    get_server_distribution $1
    if (($IS_VM)) ; then
        xl reboot -F $1
    else
        node_rank $1
        BLOCKN=${2:-$BLOCKN}
        BLOCKD=${3:-$BLOCKD}
        if (( $NLENG > 1 )); then
            parallel -j $BLOCKN \
            echo "$NPREFIX{}${NET_MGMT[4]}" \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMIUSER -P $IPMIPWD power reset \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_MGMT[4]}
            ipmitool -I $IPMITYPE -H $1${NET_MGMT[4]} -U $IPMIUSER -P $IPMIPWD power reset
        fi
    fi
}


function reset_domains()
{
    for i in ${SELF_ACTIVE_DOMAINS}
    do 
        nreset $i
    done
}

function nconsole()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: please specify the domain(s) or node(s) to connect."
    fi
    get_server_distribution $1
    if (($IS_VM)) ; then
        xl console $1 1>&3
    else
        check_host_status $1${NET_MGMT[4]}
        ipmitool -I $IPMITYPE -H $1${NET_MGMT[4]} -U $IPMIUSER -P $IPMIPWD sol deactivate
        sleep 1
        ipmitool -I $IPMITYPE -H $1${NET_MGMT[4]} -U $IPMIUSER -P $IPMIPWD sol activate 1>&3
    fi
}

function nuptime()
{
    if [ -z "$1" ]; then
        error_exit "ERROR: please, specify the domain(s) or node(s) to check the uptime."
    fi
    pdsh -w $1 uptime 
}

# End common functions

# Load additional functions in ${SNOW_TOOL}/share/common.d
if [ -d ${SNOW_TOOL}/share/common.d ]; then
  for i in ${SNOW_TOOL}/share/common.d/*.sh; do
    if [ -r $i ]; then
      source $i
    fi
  done
  unset i
fi

# Load additional functions in ${SNOW_TOOL}/share/hooks.d
if [ -d ${SNOW_TOOL}/share/hooks.d ]; then
  for i in ${SNOW_TOOL}/share/hooks.d/*.sh; do
    if [ -r $i ]; then
      source $i
    fi
  done
  unset i
fi

