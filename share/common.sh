#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website: www.hpcnow.com/snow
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
    local tmp_log=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${tmp_log}" > $LOGFILE
    chown root:root $LOGFILE
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
    For more information, visit the official website: www.hpcnow.com

    Usage: snow [function] <option|domain|server>

    Function List:

        * init                                      | setup the system according to the parameters defined in snow.conf and active-domains.conf
        * config                                    | shows the sNow! configuration based on the changes applied in snow.conf and domains.conf
        * update tools                              | updates the sNow! Tools
        * update configspace                        | updates configuration files from private git
        * update template                           | updates the sNow! image used to create new domains
        * update firewall                           | updates the default sNow! firewall rules (only for sNow! with public IP address)
        * deploy <domain|node> <template> <force>   | deploy specific domain/node (optional: with specific template or force to deploy existing domain/node)
        * add node <node> [--option value]          | adds a new node in the sNow! database. Available options: cluster, image, template, install_repo, console_options
        * set node <node> [--option value]          | sets parameters in the node description. Available options: cluster, image, template, install_repo, console_options
        * clone template <old> <new> <description>  | creates a new template based on an existing one
        * clone <node> <image> <type>               | creates an image to boot the compute nodes diskless. Available types (nfsroot, stateless, statelite).
        * remove domain <domain>                    | removes an existing domain deployed with sNow!
        * remove node <node>                        | removes an existing node from sNow! configuration
        * remove template <template>                | removes an existing template
        * remove image <image>                      | removes an existing image
        * list domains                              | list the current domains (services) and their status
        * list nodes                                | list the available compute nodes and their status
        * list templates                            | list the templates installed in the system
        * list images                               | list the images generated or downloaded
        * boot <domain>                             | boot specific domain
        * boot <node> <image>                       | boot specific node with optional image
        * boot domains                              | boot all the domains (all services not available under sNow! HA)
        * boot cluster <cluster>                    | boot all the compute nodes of the selected cluster (by default 20 nodes at once)
        * reboot <domain|node>                      | reboot specific domain or node
        * shutdown <domain|node>                    | shutdown specific domain or node
        * shutdown cluster <cluster>                | shutdown all the compute nodes of the selected cluster
        * destroy <domain|node>                     | force to stop specific domain or node
        * reset <domain|node>                       | force to reboot specific domain or node
        * poweroff <domain|node>                    | force to shutdown specific domain or node simulating a power button press
        * console <domain|node>                     | console access to specific domain or node
        * version                                   | shows the version of sNow!
        * help                                      | prints this message

    Examples:

        snow update tools
        snow deploy ldap01
    " 1>&3
}
#        * boot cluster <cluster> <image>            | boot all the compute nodes of the selected cluster (by default 20 nodes at once)

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
    Please help us to improve this project, report bugs and issues to:
    sNow! Development <dev@hpcnow.com>
    If you found some error during the installation, please review the
    log file: $LOGFILE
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
    local download_url=$1
    local download_path=$2
    case $DOWNLD in
        axel)
            axel -q -n 10 ${download_url} -o ${download_path}
        ;;
        curl)
            f=$(gawk -F'/' '{print $NF}' <<< ${download_url})
            curl ${download_url} -o ${download_path}/$f
        ;;
        wget)
            wget -q -NS --content-disposition -P ${download_path} ${download_url}
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
    if [[ "${lsb_dist}" == "redhatenterpriseserver" ]]; then
        lsb_dist='redhat'
    fi
    if [[ "${lsb_dist}" == "suselinux" || "${lsb_dist}" == "opensuseproject" ]]; then
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
            zypper --gpg-auto-import-keys refresh
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

function last_ip_in_range()
{
    local ip=$1
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
    echo ${hostip[-2]}
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
        printf "%-16s    %s\n" "${hostip[$i]}" "${host[$i]}$host_extension"
    done
}

function generate_nodes_json()
{
    local cluster="$1"
    local nodes="$2"
    if [[ -e ${SNOW_TOOL}/etc/nodes.json ]]; then
        local nodes_json=$(cat ${SNOW_TOOL}/etc/nodes.json)
    else
        local nodes_json='{"compute": {}}'
    fi
    for node in $nodes; do
        nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\" = {} ")
        nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"cluster\" = \"$cluster\"")
        nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"image\" = \"${DEFAULT_BOOT}\"")
        nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"template\" = \"${DEFAULT_TEMPLATE}\"")
        nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"install_repo\" = \"${INSTALL_REPO}\"")
        nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"console_options\" = \"${DEFAULT_CONSOLE_OPTIONS}\"")
        nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"last_deploy\" = \"null\"")
    done
    unset node
    echo "${nodes_json}" > ${SNOW_TOOL}/etc/nodes.json
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

    # If the system uses shared (and external) NFS to enable HA, then the following block will help to setup the required configuration in the
    # NFS server.
    if (! ${HA_NFSROOT}) ; then
        # NFS_ROOT Exports
        if [[ ! -d /etc/exports.d ]]; then
           mkdir -p /etc/exports.d
        fi
        if [[ ! -f ${SNOW_CONF}/system_files/etc/exports.d/snow_domains.exports ]]; then
            if [[ ! -d ${SNOW_CONF}/system_files/etc/exports.d ]]; then
                mkdir -p ${SNOW_CONF}/system_files/etc/exports.d
            fi
            local snow_servers_exports=$(echo "${SNOW_NODES[*]}(rw,sync,no_subtree_check,no_root_squash)" | sed 's/ /(rw,sync,no_subtree_check,no_root_squash) /g')
            gawk -v snow_servers_exports=$snow_servers_exports '{
                if ($1 !~ /^#|snow/){
                    print "/sNow/domains/"$1"\t "snow_servers_exports" "$1"(rw,sync,no_subtree_check,no_root_squash)"
                }
            }' ${SNOW_ACTIVE_DOMAINS} > ${SNOW_CONF}/system_files/etc/exports.d/snow_domains.exports
            ln -sf ${SNOW_CONF}/system_files/etc/exports.d/snow_domains.exports /etc/exports.d/snow_domains.exports
            warning_msg "Review the following exports file: ${SNOW_CONF}/system_files/etc/exports.d/snow_domains.exports"
            warning_msg "Once you are done, execute exportfs -u"
        fi
    fi
    #If the master is the NFS Server it will setup the ${SNOW_CONF}/system_files/etc/exports.d/snow.exports
    if [[ "$(uname -n)" == "${NFS_SERVER}" ]]; then
        if [[ ! -f ${SNOW_CONF}/system_files/etc/exports.d/snow.exports ]]; then
            if [[ ! -d ${SNOW_CONF}/system_files/etc/exports.d ]]; then
                mkdir -p ${SNOW_CONF}/system_files/etc/exports.d
            fi
            echo "/sNow            ${NET_SNOW[2]}0/${NET_SNOW[3]}(rw,sync,no_subtree_check,no_root_squash)" > ${SNOW_CONF}/system_files/etc/exports.d/snow.exports
            warning_msg "Review the following exports file: ${SNOW_CONF}/system_files/etc/exports.d/snow.exports"
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
            local macdmz=$(ip -f link addr show ${NET_DMZ[0]} | grep ether | gawk '{print $2}')
            local macsnow=$(ip -f link addr show ${NET_SNOW[0]} | grep ether | gawk '{print $2}')
            gawk -v brdmz=${NET_DMZ[0]} -v gwdmz=${NET_DMZ[1]} -v netdmz=${NET_DMZ[2]} -v maskdmz=${NET_DMZ[3]} -v macdmz=${macdmz} \
                 -v brsnow=${NET_SNOW[0]} -v gwsnow=${NET_SNOW[1]} -v netsnow=${NET_SNOW[2]} -v masksnow=${NET_SNOW[3]} -v macsnow=${macsnow} \
                'BEGIN{i=0}{
                    if ($1 !~ /^#/){
                        i=i+1
                        printf "%12s\t %20s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s \n", $1, $2, "eth0", netsnow""i, brsnow, i, "01", masksnow, gwsnow, "eth1", netdmz""i, brdmz, i, "02", maskdmz, gwdmz
                    }
                }' ${SNOW_ACTIVE_DOMAINS} >> ${SNOW_CONF}/system_files/etc/domains.conf
        else
            local macpub=$(ip -f link addr show ${NET_PUB[0]} | grep ether | gawk '{print $2}')
            local macsnow=$(ip -f link addr show ${NET_SNOW[0]} | grep ether | gawk '{print $2}')
            gawk -v brpub=${NET_PUB[0]} -v gwpub=${NET_PUB[1]} -v netpub=none -v maskpub=${NET_PUB[3]} -v macpub=${macpub} \
                 -v brsnow=${NET_SNOW[0]} -v gwsnow=${NET_SNOW[1]} -v netsnow=${NET_SNOW[2]} -v masksnow=${NET_SNOW[3]} -v macsnow=${macsnow} \
                'BEGIN{i=0}{
                    if ($1 !~ /^#/){
                        i=i+1
                        printf "%12s\t %20s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s \n", $1, $2, "eth0", netsnow""i, brsnow, i, "01", masksnow, gwsnow, "eth1", netpub, brpub, i, "02", maskpub, gwpub
                    }
                }' ${SNOW_ACTIVE_DOMAINS} >> ${SNOW_CONF}/system_files/etc/domains.conf
        fi
        ln -s ${SNOW_CONF}/system_files/etc/domains.conf ${SNOW_TOOL}/etc/domains.conf
        warning_msg "Review the domains config file: ${SNOW_TOOL}/etc/domains.conf"
    fi
    # Generate /etc/hosts based on the sNow! domains and compute node list defined in snow.conf (parameter CLUSTERS)
    host=( )
    for i in ${!CLUSTERS[@]}
    do
        node_rank ${CLUSTERS[$i]}
        host+=( $(eval echo "$NPREFIX{${NRANK[0]}..${NRANK[1]}}") )
        generate_nodes_json "$i" "$(eval echo "$NPREFIX{${NRANK[0]}..${NRANK[1]}}")"
    done
    if [[ ! -e /etc/hosts.base ]]; then
        cp -p /etc/hosts /etc/hosts.base
    fi
    bkp /etc/hosts
    gawk '{if ($1 !~ /^#/){printf "%-16s    %s\n", $4, $1}}' ${SNOW_CONF}/system_files/etc/domains.conf > $SNOW_CONF/system_files/etc/static_hosts
    generate_hostlist ${NET_SNOW[2]}100/${NET_SNOW[3]} "${NET_SNOW[4]}" >> $SNOW_CONF/system_files/etc/static_hosts
    generate_hostlist ${NET_MGMT[2]}100/${NET_MGMT[3]} "${NET_MGMT[4]}" >> $SNOW_CONF/system_files/etc/static_hosts
    generate_hostlist ${NET_LLF[2]}100/${NET_LLF[3]} "${NET_LLF[4]}" >> $SNOW_CONF/system_files/etc/static_hosts
    cat /etc/hosts.base $SNOW_CONF/system_files/etc/static_hosts > /etc/hosts

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
    if ( ! $(grep "HostbasedAuthentication yes" /etc/ssh/ssh_config | grep -qv "^#") ); then
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
        cd -
    fi
} 1>>$LOGFILE 2>&1

function update_configspace()
{
    if [[ -z "$PRIVATE_GIT_TOKEN" || -z "$PRIVATE_GIT_REPO" ]]; then
        error_exit "ERROR: your private git repo and token are not defined. sNow! is not able to update without these two parameters."
    else
        if [[ ! -d ${SNOW_CONF}  ]]; then
            mkdir -p ${SNOW_CONF}
            cd ${SNOW_CONF}
            git pull https://$PRIVATE_GIT_TOKEN:x-oauth-basic@$PRIVATE_GIT_REPO || error_exit "ERROR: please review the SSH certificates in your bitbucket."
            cd -
        else
            cd ${SNOW_CONF}
            git pull https://$PRIVATE_GIT_TOKEN:x-oauth-basic@$PRIVATE_GIT_REPO || error_exit "ERROR: please review the SSH certificates in your bitbucket."
            cd -
        fi
    fi
} 1>>$LOGFILE 2>&1

function update_firewall()
{
    local pub_nic=${NET_PUB[0]}
    local pub_mac=$(ip -f link addr show ${pub_nic} | gawk '{if($0 ~ /ether/){print $2}}')
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
        local md5local=$(md5sum ${SNOW_PATH}/domains/template/snow-template.tar.bz2 | gawk '{ print $1 }')
        wget http://snow.hpcnow.com/snow-template.md5sum -P ${SNOW_PATH}/domains/template || error_exit "ERROR: the image can not be downloaded. Please check your network setup."
        local md5hpcnow=$(cat ${SNOW_PATH}/domains/template/snow-template.md5sum | gawk '{ print $1 }')
        if [[ "$md5local" != "$md5hpcnow" ]]; then
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

function deploy_domain_xen()
{
    local domain=$1
    get_server_distribution ${domain}
    if [[ -f ${SNOW_PATH}/snow-tools/etc/domains/${domain}.cfg ]]; then
        if [[ "$opt3" != "force" ]]; then
            error_exit "The domain ${domain} already exist, please use 'force' option to overwrite the domain or remove it first with: snow remove ${domain}."
        else
            warning_msg "The domain ${domain} will be installed and all the data contained in this domain will be removed."
            remove_domain_xen ${domain}
            FORCE="--force"
        fi
    else
        if (($IS_VM)) ; then
            info_msg "Deploying the domain ${domain}. It can take few minutes. Please wait!"
        else
            error_exit "The domain ${domain} is NOT available in the ${SNOW_DOMAINS}."
        fi
    fi

    if [[ -n "$IMG_DST" ]]; then
        IMG_DST_OPT="--${IMG_DST}"
    fi
    cat ${SNOW_DOMAINS} | grep "${domain}" | gawk -v force="$FORCE" -v img_dst="$IMG_DST_OPT" -v pwd="$MASTER_PASSWORD" '{
        hostname=$1; role=$2; dev_nic1=$3; ip_nic1=$4; bridge_nic1=$5; mac_nic1=$6; mask_nic1=$7; gw_nic1=$8
        }
        END{
        system("xen-create-image --config=/sNow/snow-tools/etc/xen-tools.conf --roledir=/sNow/snow-tools/etc/role.d --hostname="hostname" --mac="mac_nic1" --bridge="bridge_nic1" --ip="ip_nic1" --gateway="gw_nic1" --netmask="mask_nic1" --role=snow,"role" --copyhosts --password=\""pwd"\" "force" "img_dst)
        }'
    if [[ ! -f ${SNOW_PATH}/snow-tools/etc/domains/${domain}.cfg ]]; then
        error_exit "Unable to install the domain, please report the issue to HPCNow!"
        error_check 1 "Deployment of ${domain} Failed."
    else
        second_nic=$(gawk -v guest=${domain} '{if($1 == guest){print $10}}' ${SNOW_DOMAINS})
        if [[ "$second_nic" != "none" && -e ${SNOW_TOOL}/etc/domains/${domain}.cfg ]]; then
            guest_network=$(gawk -v guest=${domain} '{if($1 == guest){print "vif        = [ '\''ip="$4", mac="$6", bridge="$5"'\'', '\''ip="$10", mac="$12", bridge="$11"'\'' ]"}}' ${SNOW_DOMAINS})
            gawk -v gnet="$guest_network" '{if($1 == "vif"){print gnet}else{print $0}}' ${SNOW_TOOL}/etc/domains/${domain}.cfg > ${SNOW_TOOL}/etc/domains/${domain}.cfg.extended
            mv ${SNOW_TOOL}/etc/domains/${domain}.cfg.extended ${SNOW_TOOL}/etc/domains/${domain}.cfg
        fi
        error_check 0 "Deployment of ${domain} completed."
    fi
} 1>>$LOGFILE 2>&1

function remove_domain_xen()
{
    local domain=$1
    get_server_distribution $domain
    if [[ ! -f ${SNOW_PATH}/snow-tools/etc/domains/$domain.cfg ]]; then
        error_msg "There is no domain with this name. Please, review the name of the domain to be removed."
    else
        if [[ -n "$IMG_DST" ]]; then
            IMG_DST_OPT="--${IMG_DST}"
        fi
        warning_msg "Do you want to remove the domain ${domain}? [y/N] (20 seconds)"
        read -t 20 -u 3 answer
        if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
            xl destroy ${domain}
            xen-delete-image $IMG_DST_OPT --hostname=${domain}
            rm -f ${SNOW_PATH}/snow-tools/etc/domains/${domain}.cfg
        else
            info_msg "Well done. It's better to be sure."
        fi
    fi
} 1>>$LOGFILE 2>&1

function remove_template()
{
    local template=$1
    if [[ ! -f ${SNOW_CONF}/boot/templates/${template}/${template}.pxe ]]; then
        error_msg "There is no template with this name. Please, review the name with: snow list templates."
    else
        warning_msg "Do you want to remove the template ${template}? [y/N] (20 seconds)"
        read -t 20 -u 3 answer
        if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -fr ${SNOW_CONF}/boot/templates/${template}/
        else
            info_msg "Well done. It's better to be sure."
        fi
    fi
} 1>>$LOGFILE 2>&1

function remove_image()
{
    local image=$1
    if [[ ! -f ${SNOW_CONF}/boot/images/${image}/${image}.pxe ]]; then
        error_msg "There is no image with this name. Please, review the name with: snow list images."
    else
        warning_msg "Do you want to remove the image ${image}? [y/N] (20 seconds)"
        read -t 20 -u 3 answer
        if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -fr ${SNOW_CONF}/boot/images/${image}/
        else
            info_msg "Well done. It's better to be sure."
        fi
    fi
} 1>>$LOGFILE 2>&1

function remove_node()
{
    local nodelist=$1
    local nodes_json=$(cat ${SNOW_TOOL}/etc/nodes.json)
    for node in $(node_list "${nodelist}"); do
        node_query=$(echo ${nodes_json} | jq -r ".\"compute\".\"${node}\"")
        if [[ "${node_query}" == "null" ]]; then
            error_msg "There is no node with this name ($node). Please, review the name with: snow list nodes."
        else
            nodes_json=$(echo "${nodes_json}" | jq "del(.\"compute\".\"${node}\")")
        fi
        warning_msg "Do you want to remove the node(s) ${nodelist}? [y/N] (20 seconds)"
        read -t 20 -u 3 answer
        if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "${nodes_json}" > ${SNOW_TOOL}/etc/nodes.json
        else
            info_msg "Well done. It's better to be sure."
        fi
    done
} 1>>$LOGFILE 2>&1

function add_node()
{
    local nodelist=$1
    local cluster=""
    local image=${DEFAULT_BOOT} 
    local template=${DEFAULT_TEMPLATE}
    local install_repo=${INSTALL_REPO}
    local console_options=${DEFAULT_CONSOLE_OPTIONS}
    local last_deploy=null
    shift
    local nodes_json=$(cat ${SNOW_TOOL}/etc/nodes.json)
    while test $# -gt 0; do
        case "$1" in
            -c|--cluster)
                if [ -n "$2" ]; then
                    cluster="$2"
                    shift
                else
                    error_exit "Option cluster missing"
                fi
                ;;
            -i|--image)
                if [ -n "$2" ]; then
                    image="$2"
                    shift
                else
                    error_exit "Option image missing"
                fi
                ;;
            -t|--template)
                if [ -n "$2" ]; then
                    template="$2"
                    shift
                else
                    error_exit "Option template missing"
                fi
                ;;
            -r|--install_repo)
                if [ -n "$2" ]; then
                    install_repo="$2"
                    shift
                else
                    error_exit "Option install_repo missing"
                fi
                ;;
            -C|--console_options)
                if [ -n "$2" ]; then
                    console_options="$2"
                    shift
                else
                    error_exit "Option console_options missing"
                fi
                ;;
            -?|-h|--help)
                shelp
                exit
                ;;
            *)
                error_exit "Option ($1) not recognised"
                break
                ;;
        esac
        shift
    done

    if [[ -z "$cluster" ]]; then
        error_exit "The cluster name is not provided"
    fi
    for node in $(node_list "${nodelist}"); do
        node_query=$(echo ${nodes_json} | jq -r ".\"compute\".\"${node}\"")
        if [[ "${node_query}" != "null" ]]; then
            error_msg "There node $node already exist in the database."
        else
            nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\" = {} ")
            # setup the defaults
            if [[ -n "$cluster" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"cluster\" = \"$cluster\"")
            fi
            if [[ -n "$image" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"image\" = \"${image}\"")
            fi
            if [[ -n "$template" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"template\" = \"${template}\"")
            fi
            if [[ -n "$install_repo" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"install_repo\" = \"${install_repo}\"")
            fi
            if [[ -n "$console_options" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"console_options\" = \"${console_options}\"")
            fi
        fi
    done
    unset node
    warning_msg "Do you want to add the node(s) ${nodelist}? [y/N] (20 seconds)"
    read -t 20 -u 3 answer
    if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "${nodes_json}" > ${SNOW_TOOL}/etc/nodes.json
    else
        info_msg "Well done. It's better to be sure."
    fi
} 1>>$LOGFILE 2>&1

function set_node()
{
    local nodelist=$1
    shift
    local nodes_json=$(cat ${SNOW_TOOL}/etc/nodes.json)
    while test $# -gt 0; do
        case "$1" in
            -c|--cluster)
                if [ -n "$2" ]; then
                    local cluster="$2"
                    shift
                else
                    error_exit "Option cluster missing"
                fi
                ;;
            -i|--image)
                if [ -n "$2" ]; then
                    local image="$2"
                    shift
                else
                    error_exit "Option image missing"
                fi
                ;;
            -t|--template)
                if [ -n "$2" ]; then
                    local template="$2"
                    shift
                else
                    error_exit "Option template missing"
                fi
                ;;
            -r|--install_repo)
                if [ -n "$2" ]; then
                    local install_repo="$2"
                    shift
                else
                    error_exit "Option install_repo missing"
                fi
                ;;
            -C|--console_options)
                if [ -n "$2" ]; then
                    local console_options="$2"
                    shift
                else
                    error_exit "Option console_options missing"
                fi
                ;;
            -?|-h|--help)
                shelp
                exit
                ;;
            *)
                error_exit "Option ($1) not recognised"
                break
                ;;
        esac
        shift
    done

    for node in $(node_list "${nodelist}"); do
        node_query=$(echo ${nodes_json} | jq -r ".\"compute\".\"${node}\"")
        if [[ "${node_query}" == "null" ]]; then
            error_msg "There node $node does not exist in the database."
        else
            # setup the defaults
            if [[ -n "$cluster" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"cluster\" = \"$cluster\"")
            fi
            if [[ -n "$image" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"image\" = \"${image}\"")
            fi
            if [[ -n "$template" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"template\" = \"${template}\"")
            fi
            if [[ -n "$install_repo" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"install_repo\" = \"${install_repo}\"")
            fi
            if [[ -n "$console_options" ]]; then
                nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"console_options\" = \"${console_options}\"")
            fi
        fi
    done
    unset node
    warning_msg "Do you want to apply the changes in the node(s) ${nodelist}? [y/N] (20 seconds)"
    read -t 20 -u 3 answer
    if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "${nodes_json}" > ${SNOW_TOOL}/etc/nodes.json
    else
        info_msg "Well done. It's better to be sure."
    fi
} 1>>$LOGFILE 2>&1

function expand_range()
{
    IFS=" "
    local nprefix=$1
    local node_range=$2
    if [[ -n "$(echo ${node_range} | grep -o '[0-9]\+\-[0-9]\+')" ]]; then
        local range=($(echo ${node_range} | sed -e 's/-/ /'))
        echo $(eval echo "${nprefix}{${range[0]}..${range[1]}}")
    else
        echo ${nprefix}${node_range}
    fi
}

function node_list()
{
    OFIS="${IFS}"
    local node_range=$1
    local nodes=()
    if [[ "${node_range}" =~ \] ]]; then
        local nprefix=$(echo ${node_range} | cut -d"[" -f1)
        local nrange=$(echo ${node_range} | cut -d"[" -f2| cut -d"]" -f1)
        IFS=","
        for range in ${nrange}; do
            nodes+="$(expand_range ${nprefix} ${range}) "
        done
        local nleng=${#nodes[@]}
    else
        local nleng=0
        nodes=${node_range}
    fi
    IFS="${OIFS}"
    echo ${nodes}
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
    local default_config=$2
    local nodelist=$3
    source ${default_config}
    for node in $(node_list "${nodelist}"); do
        local node_hash=$(gethostip $node | gawk '{print $3}')
        local console_options=$(echo ${nodes_json} | jq -r ".\"compute\".\"${node}\".\"console_options\"")
        local install_repo=$(echo ${nodes_json} | jq -r ".\"compute\".\"${node}\".\"install_repo\"")
        if [[ "${console_options}" == "null" ]]; then
            console_options=${DEFAULT_CONSOLE_OPTIONS}
        fi
        if [[ "${install_repo}" == "null" ]]; then
            install_repo=${INSTALL_REPO}
        fi
        cp -p ${pxelinux_cfg} ${SNOW_CONF}/boot/pxelinux.cfg/${node_hash}
        sed -i "s|__CONSOLE_OPTIONS__|${console_options}|g" ${SNOW_CONF}/boot/pxelinux.cfg/${node_hash}
        sed -i "s|__INSTALL_REPO__|${install_repo}|g" ${SNOW_CONF}/boot/pxelinux.cfg/${node_hash}
    done
    unset node
}

function list_templates()
{
    local templates_path=${SNOW_CONF}/boot/templates
    local templates_avail=$(ls -1 ${templates_path}/*/*.pxe | sed -e "s|${templates_path}||g" | cut -d"/" -f1)
    for template in ${templates_avail}; do
        local template_desc=${templates_path}/${template}/${template}.desc
        print_msg "$template"
        cat ${template_desc} | tee /dev/fd/3
    done
}

function deploy()
{
    local nodelist=$opt2
    if [[ -z "${nodelist}" ]]; then
        error_exit "ERROR: No domain or node to deploy"
    fi
    get_server_distribution ${nodelist}
    if (($IS_VM)) ; then
        deploy_domain_xen ${nodelist} $2
    else
        if [[ -z "$opt4" ]]; then
            if [[ -z "$opt3" ]]; then
                local template=${DEFAULT_TEMPLATE}
                warning_msg "sNow! will start to deploy the following node(s) ${nodelist} in 10 seconds, unless you interrupt that with 'Ctrl+C'."
                info_msg "Use 'force' option to avoid the waiting."
                sleep 10
            elif [[ "$opt3" == "force"  ]]; then
                local template=${DEFAULT_TEMPLATE}
                warning_msg "The node(s) ${nodelist} will be deployed with $template template. All the data located in the local file system will be removed."
            else
                local template=$opt3
                warning_msg "sNow! will start to deploy the following node(s) ${nodelist} in 10 seconds, unless you interrupt that with 'Ctrl+C'."
                info_msg "Use 'force' option to avoid the waiting."
                sleep 10
            fi
        else
            if [[ "$opt4" == "force" ]]; then
                local template=$opt3
                warning_msg "The node(s) ${nodelist} will be deployed with $template template. All the data located in the local file system will be removed."
            else
                error_exit "sNow! deploy only supports the following options: snow deploy <domain|server> <template> <force>"
            fi
        fi
        local template_pxe=${SNOW_CONF}/boot/templates/${template}/${template}.pxe
        local template_config=${SNOW_CONF}/boot/templates/${template}/config
        local default_boot_pxe=${SNOW_CONF}/boot/images/${DEFAULT_BOOT}/${DEFAULT_BOOT}.pxe
        local default_boot_config=${SNOW_CONF}/boot/images/${DEFAULT_BOOT}/${DEFAULT_BOOT}.pxe
        local nodes_json=$(cat ${SNOW_TOOL}/etc/nodes.json)
        if ! [[ -f ${template_pxe} ]] ; then
            error_exit "No template $template available in ${SNOW_CONF}/boot/templates/"
        fi
        for node in $(node_list "${nodelist}"); do
            nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"template\" = \"${template}\"")
            nodes_json=$(echo "${nodes_json}" | jq ".\"compute\".\"${node}\".\"last_deploy\" = \"$(date)\"")
        done
        unset node
        echo "${nodes_json}" > ${SNOW_TOOL}/etc/nodes.json
        info_msg "Booting node range ${nodelist} for deployment... This will take a while, Please wait."
        boot_copy ${template_pxe} ${template_config} "${nodelist}"
        parallel -j $BLOCKN \
        echo "{}${NET_MGMT[4]}" \; \
        ipmitool -I $IPMI_TYPE -H "{}${NET_MGMT[4]}" -U $IPMI_USER -P $IPMI_PASSWORD power reset \; \
        sleep 5 \; \
        ipmitool -I $IPMI_TYPE -H "{}${NET_MGMT[4]}" -U $IPMI_USER -P $IPMI_PASSWORD power on \; \
        sleep $BLOCKD \
        ::: $(node_list "${nodelist}")
        sleep $BOOT_DELAY
        info_msg "You can monitor the deployment with: snow console <compute-node-name>"
        boot_copy ${default_boot_pxe} ${default_boot_config} "${nodelist}"
        error_check 0 "Deployment started."
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
    local image=$1
    mkdir -p ${SNOW_CONF}/boot/images/$image/
    case $OS in
        debian|ubuntu)
            cp -p /boot/initrd.img-$(uname -r) ${SNOW_CONF}/boot/images/$image/initrd.img
            cp -p /boot/vmlinuz-$(uname -r) ${SNOW_CONF}/boot/images/$image/vmlinuz
        ;;
        rhel|redhat|centos)
            dracut --nomdadmconf --nolvmconf --xz --no-early-microcode --add "nfs network base ssh-client lvm dm dmraid mdraid multipath iscsi rdma" --add-drivers "nfs nfsv4 squashfs" root=dhcp --host-only -f ${SNOW_CONF}/boot/images/$image/initrd.img $(uname -r)
            cp -p /boot/vmlinuz-$(uname -r) ${SNOW_CONF}/boot/images/$image/vmlinuz
       ;;
       suse|sle[sd]|opensuse)
           kiwi --root / --add-profile netboot --type pxe -d ${SNOW_CONF}/boot/images/$image
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
                $hook && error_check 0 "Running hook: $hook " || error_check 1 "Running hook error: $hook " &
                spinner $!             "Running hook: $hook "
            else
                warning_msg "File '$hook' is not executable. If you want to run it, do: chmod 750 $hook"
            fi
        done
    fi
}

function first_boot_hooks()
{
    local hooks_path=$1
    cp -p ${hooks_path}/first_boot/first_boot.service  /lib/systemd/system/
    cp -p ${hooks_path}/first_boot/first_boot /usr/local/bin/first_boot
    chmod 700 /usr/local/bin/first_boot
    systemctl enable first_boot
} 1>>$LOGFILE 2>&1

function generate_rootfs()
{
    local image=$1
    # set mount point for the rootfs
    local mount_point="/root/rootfs"
    # create a mount point
    mkdir -p ${mount_point}
    # Transfer required files
    rsync -av --progress --exclude=/proc/* --exclude=/sys/* --exclude=/sNow/* --exclude=/tmp/* --exclude=/dev/* --exclude=/var/log/* / ${mount_point}/
    # Create required directory structure
    mkdir -p ${mount_point}/{bin,boot,dev,etc,home,lib64,mnt,proc,root/.ssh,sbin,sys,usr,var/{lib,log,run,tmp},var/lib/nfs,tmp,var/run/netreport,var/lock/subsys}
    # set required permissions
    chown root:lock ${mount_point}var/lock
    # Update fstab
    bkp ${mount_point}/etc/fstab
    # Patch the network
    patch_network_configuration
    # Create the tarball
    tar -cf /root/rootfs.tar --acls -C ${mount_point}/ .
    # Compress the tarball in parallel
    pigz -9 /root/rootfs.tar
    # Transfer the rootfs to the shared file system
    cp -p /root/rootfs.tar.gz ${SNOW_CONF}/boot/images/$image/rootfs.tar.gz
}

function generate_rootfs_nfs()
{
    local image=$1
    # path to the PXE config file
    local image_pxe=${SNOW_CONF}/boot/images/${image}/${image}.pxe
    # raw rootfs image
    local image_rootfs=${SNOW_CONF}/boot/images/${image}/rootfs.tar.gz
    # set mount point for the rootfs
    local mount_point=${SNOW_CONF}/boot/images/${image}/rootfs
    # create the nfsroot image
    mkdir -p ${mount_point}
    # Extract raw rootfs into the nfsroot folder
    tar -C ${mount_point} -zxf ${image_rootfs}
    # Update fstab
    bkp ${mount_point}/etc/fstab
    cp -p ${mount_point}/etc/fstab ${mount_point}/etc/fstab.orig
    echo "proc        /proc       proc    defaults    0 0"  > ${mount_point}/etc/fstab
    echo "/dev/nfs    /           nfs     tcp,nolock  0 0" >> ${mount_point}/etc/fstab
    echo "none        /tmp        tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "none        /var/tmp    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "none        /var/log    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "tmpfs       /dev/shm    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "sysfs       /sys        sysfs   defaults    0 0" >> ${mount_point}/etc/fstab
    # Run hooks:
    hooks ${SNOW_CONF}/boot/images/$image
    # Setup the first boot hooks
    first_boot_hooks ${SNOW_CONF}/boot/images/$image
    # Setup NFSROOT support for PXE
    cp -p ${SNOW_CONF}/boot/pxelinux.cfg/nfsroot ${image_pxe}
    sed -i "s|__IMAGE__|$image|g" ${image_pxe}
    sed -i "s|__NFS_SERVER__|${NFS_SERVER}|g" ${image_pxe}
}

function generate_rootfs_squashfs()
{
    local image=$1
    # path to the PXE config file
    local image_pxe=${SNOW_CONF}/boot/images/${image}/${image}.pxe
    # raw rootfs image
    local image_rootfs=${SNOW_CONF}/boot/images/${image}/rootfs.tar.gz
    # set mount point for the rootfs
    local mount_point=${SNOW_CONF}/boot/images/${image}/rootfs
    # create the squashfs rootfs working dir
    mkdir -p ${mount_point}
    # Extract raw rootfs into the squashfs working dir
    tar -C ${mount_point} -zxf ${image_rootfs}
    # Update fstab
    bkp ${mount_point}/etc/fstab
    cp -p ${mount_point}/etc/fstab ${mount_point}/etc/fstab.orig
    echo "proc        /proc       proc    defaults    0 0"  > ${mount_point}/etc/fstab
    echo "none        /tmp        tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "none        /var/tmp    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "none        /var/log    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "tmpfs       /dev/shm    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "sysfs       /sys        sysfs   defaults    0 0" >> ${mount_point}/etc/fstab
    # Run hooks:
    hooks ${SNOW_CONF}/boot/images/$image
    # Setup the first boot hooks
    first_boot_hooks ${SNOW_CONF}/boot/images/$image
    # Generate the squasfs image
    mksquashfs ${mount_point} rootfs -e boot
    # Setup squashfs support for PXE
    cp -p ${SNOW_CONF}/boot/pxelinux.cfg/stateless ${image_pxe}
    sed -i "s|__IMAGE__|$image|g" ${image_pxe}
    sed -i "s|__NFS_SERVER__|${NFS_SERVER}|g" ${image_pxe}
}

function generate_rootfs_stateless()
{
    local image=$1
    # path to the PXE config file
    local image_pxe=${SNOW_CONF}/boot/images/${image}/${image}.pxe
    # raw rootfs image
    local image_rootfs=${SNOW_CONF}/boot/images/${image}/rootfs.tar.gz
    # set mount point for the rootfs
    local mount_point=${SNOW_CONF}/boot/images/${image}/rootfs
    # create the nfsroot image
    mkdir -p ${mount_point}
    # Extract raw rootfs into the nfsroot folder
    tar -C ${mount_point} -zxf ${image_rootfs}
    # Update fstab
    bkp ${mount_point}/etc/fstab
    cp -p ${mount_point}/etc/fstab ${mount_point}/etc/fstab.orig
    echo "proc        /proc       proc    defaults    0 0"  > ${mount_point}/etc/fstab
    echo "/dev/ram0   /           ramfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "none        /tmp        tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "none        /var/tmp    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "none        /var/log    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "tmpfs       /dev/shm    tmpfs   defaults    0 0" >> ${mount_point}/etc/fstab
    echo "sysfs       /sys        sysfs   defaults    0 0" >> ${mount_point}/etc/fstab
    # Run hooks:
    hooks ${SNOW_CONF}/boot/images/$image
    # Setup the first boot hooks
    first_boot_hooks ${SNOW_CONF}/boot/images/$image
    # Generate the ramfs image
    cd ${mount_point}
    ln -s ./sbin/init ./init
    find . -print0 | sudo cpio --null -ov --format=newc | pigz -9 > ${SNOW_CONF}/boot/images/$image/rootfs.gz
    cd ..
    # Setup squashfs support for PXE
    cp -p ${SNOW_CONF}/boot/pxelinux.cfg/diskless ${image_pxe}
    sed -i "s|__IMAGE__|$image|g" ${image_pxe}
    sed -i "s|__NFS_SERVER__|${NFS_SERVER}|g" ${image_pxe}
}

function clone_template()
{
    local old_template="$1"
    local new_template="$2"
    local new_description="$3"
    if [[ -z "${old_template}" ]]; then
        error_exit "ERROR: no template name to clone is provided"
    fi
    if [[ -z "${new_template}" ]]; then
        error_exit "ERROR: no name is provided for the new template"
    fi
    if [[ ! -f ${SNOW_CONF}/boot/templates/${old_template}/${old_template}.pxe ]]; then
        error_msg "There is no template with this name (${old_template}). Please, review the name with: snow list templates."
    else
        if [[ -f ${SNOW_CONF}/boot/templates/${new_template}/${new_template}.pxe ]]; then
            error_msg "The template ${new_template} already exist. Please remove it before to create a new one."
        fi
        cp -pr ${SNOW_CONF}/boot/templates/${old_template} ${SNOW_CONF}/boot/templates/${new_template}
        grep -rl "${old_template}" ${SNOW_CONF}/boot/templates/${new_template}/* | xargs sed -i "s|${old_template}|${new_template}|g"
        for extension in cfg pxe; do
            mv ${SNOW_CONF}/boot/templates/${new_template}/${old_template}.$extension ${SNOW_CONF}/boot/templates/${new_template}/${new_template}.$extension
        done
        if [[ ! -z "${new_description}" ]]; then
            echo "${new_description}" > ${SNOW_CONF}/boot/templates/${new_template}/description
        fi
    fi
}

function clone_node()
{
    local node=$1
    local image=$2
    local image_type=$3
    if [[ -z "$node" ]]; then
        error_exit "ERROR: no node name to clone is provided"
    fi
    if [[ -z "$image" ]]; then
        error_exit "ERROR: no name is provided for the image"
    fi
    if [[ -z "${image_type}" ]]; then
        error_exit "ERROR: no type of image is provided"
    fi
    # Check if snow CLI is executed in the same golden node or from the snow server
    if [[ "$(uname -n)" == "$node" ]]; then
        if [[ -f ${SNOW_CONF}/boot/images/$image/rootfs.gz ]]; then
            warning_msg "This will overwrite the image $image"
        else
            warning_msg "This will clone $node and generate the image $image."
        fi
        get_server_distribution $node
        case ${image_type} in
            nfsroot)
                generate_pxe_image $image
                generate_rootfs $image
                #generate_rootfs_nfs $image
            ;;
            stateless)
                generate_rootfs_squashfs $image
            ;;
            statelite)
                generate_rootfs_lite $image
                generate_rootfs_unionfs $image
            ;;
            *)
                error_exit "Error: ${image_type} is not supported"
            ;;
        esac
    else
        check_host_status ${node}${NET_MGMT[4]}
        ssh $node $0 clone $@
    fi
}

function avail_domains()
{
    local domains_cfg=$(find $SNOW_TOOL/etc/domains/ -type f -name "*.cfg")
    printf "%-20s  %-10s  %-40s  %-20s\n" "Domain" "HW status" "OS status" "Roles" 1>&3
    printf "%-20s  %-10s  %-40s  %-20s\n" "------" "---------" "---------" "-----" 1>&3
    #for domain in ${SELF_ACTIVE_DOMAINS}; do
    for domain_cfg in ${domains_cfg}; do
        domain=$(cat ${domain_cfg} | sed -e "s|'||g" | gawk '{if($1 ~ /^name/){print $3}}')
        if [[ ! -z $domain ]]; then
            hw_status="$(xl list ${domain} &>/dev/null && echo "on" || echo "off")"
            if [[ "$hw_status" == "on" ]]; then
                os_status="$(ssh ${domain} uptime -p || echo 'down')"
            else
                os_status="down"
            fi
            roles=$(gawk -v domain=${domain}  '{if($1 == domain){print $2}}' ${SNOW_DOMAINS})
            printf "%-20s  %-10s  %-40s  %-20s\n" "${domain}" "${hw_status}" "${os_status}" "${roles}" 1>&3
        fi
    done
}

function avail_templates()
{
    local templates=$(find $SNOW_CONF/boot/templates/ -type d | sed -e "s|$SNOW_CONF/boot/templates/||g")
    printf "%-30s    %-80s\n" "Template Name" "Description" 1>&3
    printf "%-30s    %-80s\n" "-------------" "-----------" 1>&3
    for tmpl in $templates; do
        if [[ -e $SNOW_CONF/boot/templates/${tmpl}/${tmpl}.pxe ]]; then
            if [[ -e $SNOW_CONF/boot/templates/${tmpl}/description ]]; then
                desc=$(cat $SNOW_CONF/boot/templates/${tmpl}/description)
            else
                desc=""
            fi
            printf "%-30s    %-80s\n" "$tmpl" "$desc" 1>&3
            printf "%-30s    %-80s\n" "" "path: ${SNOW_CONF}/boot/templates/${tmpl}" 1>&3
            hooks=$(ls -1 ${SNOW_CONF}/boot/templates/${tmpl}/??-*.sh)
            if [[ ! -z $hooks ]]; then
                printf "%-30s    %-80s\n" "" "hooks:" 1>&3
                for hook in $hooks; do
                    if [[ -x "$hook" ]]; then
                        hookname=$(echo $hook | sed -e "s|$SNOW_CONF/boot/templates/$tmpl/||g")
                        printf "%-30s    %-80s\n" "" "- $hookname" 1>&3
                    fi
                done
            fi
        fi
    done
}

function avail_images()
{
    local images=$(find $SNOW_CONF/boot/images/ -type d | sed -e "s|$SNOW_CONF/boot/images/||g")
    printf "%-30s    %-80s\n" "Image Name" "Description" 1>&3
    printf "%-30s    %-80s\n" "-------------" "-----------" 1>&3
    for img in $images; do
        if [[ -e $SNOW_CONF/boot/images/${img}/${img}.pxe ]]; then
            if [[ -e $SNOW_CONF/boot/images/${img}/description ]]; then
                desc=$(cat $SNOW_CONF/boot/images/${img}/description)
            else
                desc=""
            fi
            printf "%-30s    %-80s\n" "$img" "$desc" 1>&3
            printf "%-30s    %-80s\n" "" "path: ${SNOW_CONF}/boot/images/${img}" 1>&3
            hooks=$(ls -1 ${SNOW_CONF}/boot/images/${img}/??-*.sh)
            if [[ ! -z $hooks ]]; then
                printf "%-30s    %-80s\n" "" "hooks:" 1>&3
                for hook in $hooks; do
                    if [[ -x "$hook" ]]; then
                        hookname=$(echo $hook | sed -e "s|$SNOW_CONF/boot/images/$img/||g")
                        printf "%-30s    %-80s\n" "" "- $hookname" 1>&3
                    fi
                done
            fi
        fi
    done
}

function avail_nodes()
{
    if [[ -z $1 ]]; then
        for i in "${!CLUSTERS[@]}"; do
            node_rank ${CLUSTERS[$i]}
            nodes+=( $(eval echo "$NPREFIX{${NRANK[0]}..${NRANK[1]}}") )
        done
    else
        node_rank $1
        nodes=( $(eval echo "$NPREFIX{${NRANK[0]}..${NRANK[1]}}") )
    fi
    printf "%-20s  %-15s  %-10s  %-44s  %-20s  %-30s  %-22s\n" "Node" "Cluster" "HW status" "OS status" "Image" "Template" "Last Deploy" 1>&3
    printf "%-20s  %-15s  %-10s  %-44s  %-20s  %-30s  %-22s\n" "----" "-------" "---------" "---------" "-----" "--------" "-----------" 1>&3
    for node in ${nodes[@]}; do
        ping -c 1 -W 1 ${node}${NET_MGMT[4]} &> /dev/null
        if [[ "$?" != "0" ]]; then
            hw_status="IPMI down"
        else
            hw_status="$(ipmitool -I $IPMI_TYPE -H ${node}${NET_MGMT[4]} -U $IPMI_USER -P $IPMI_PASSWORD power status | gawk '{print $4}' || echo 'IPMI down')"
        fi
        ping -c 1 -W 1 ${node} &> /dev/null
        if [[ "$?" != "0" ]]; then
            os_status="down"
        else
            os_status="$(ssh ${node} uptime -p || echo 'down')"
        fi
        cluster=$(jq ".\"compute\".\"${node}\".\"cluster\"" ${SNOW_TOOL}/etc/nodes.json | sed -e 's|"||g')
        current_image=$(jq ".\"compute\".\"${node}\".\"image\"" ${SNOW_TOOL}/etc/nodes.json | sed -e 's|"||g')
        current_template=$(jq ".\"compute\".\"${node}\".\"template\"" ${SNOW_TOOL}/etc/nodes.json | sed -e 's|"||g')
        last_deploy=$(jq ".\"compute\".\"${node}\".\"last_deploy\"" ${SNOW_TOOL}/etc/nodes.json | sed -e 's|"||g')
        printf "%-20s  %-15s  %-10s  %-44s  %-20s  %-30s  %-22s\n" "${node}" "${cluster}" "${hw_status}" "${os_status}" "${current_image}" "${current_template}" "${last_deploy}" 1>&3
    done
    unset node
}

function check_host_status()
{
    local host=$1
    ping -c 1 ${host} &> /dev/null
    if [[ "$?" != "0" ]]; then
        error_exit "The host ${host} is not responsive. Please check the host name, DNS server or /etc/hosts."
    fi
}

function boot()
{
    local node=$1
    if [ -z "$node" ]; then
        error_exit "ERROR: No domain or node to boot."
    fi
    get_server_distribution $node
    if (($IS_VM)) ; then
        if [[ -f ${SNOW_PATH}/snow-tools/etc/domains/${node}${DOM_EXT}.cfg ]]; then
            IS_UP=$(xl list $node)
            if [[ "$IS_UP" == "" ]]; then
                sleep 1
                xl create ${SNOW_PATH}/snow-tools/etc/domains/${node}${DOM_EXT}.cfg
            else
                warning_msg "The domain $node is already runnning"
            fi
        else
            error_exit "The domain $node needs to be deployed first. Execute: snow deploy $node"
        fi
    else
        local image=$2
        local image_pxe=${SNOW_CONF}/boot/images/${image}/${image}.pxe
        local default_boot_pxe=${SNOW_CONF}/boot/images/${DEFAULT_BOOT}/${DEFAULT_BOOT}.pxe
        node_rank $node
        BLOCKN=${2:-$BLOCKN}
        BLOCKD=${3:-$BLOCKD}
        if (( $NLENG > 0 )); then
            if [ -z "$image" ]; then
                boot_copy ${default_boot_pxe}
            else
                boot_copy ${image_pxe}
            fi
            parallel -j $BLOCKN \
            echo "$NPREFIX{}${NET_MGMT[4]}" \; \
            sleep $BLOCKD \; \
            ipmitool -I $IPMI_TYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMI_USER -P $IPMI_PASSWORD power on \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            if [ -z "$image" ]; then
                cp -p ${default_boot_pxe} ${SNOW_CONF}/boot/pxelinux.cfg/$(gethostip $node | gawk '{print $3}')
            else
                cp -p ${image_pxe} ${SNOW_CONF}/boot/pxelinux.cfg/$(gethostip $node | gawk '{print $3}')
            fi
            check_host_status $node${NET_MGMT[4]}
            ipmitool -I $IPMI_TYPE -H $node${NET_MGMT[4]} -U $IPMI_USER -P $IPMI_PASSWORD power on
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
    for domain in ${SELF_ACTIVE_DOMAINS}
    do
        boot $domain
    done
    unset domain
}

function boot_cluster()
{
    local cluster=$1
    if [ -z "${cluster}" ]; then
        error_exit "ERROR: No cluster to boot."
    fi
    BLOCKN=${2:-$BLOCKN}
    BLOCKD=${3:-$BLOCKD}
    # In order to avoid power consumption peaks, the nodes needs to be booted in a blocks of few nodes with a delayed (5 seconds) timing between blocks
    # BlockN is the number of nodes to be iniciated at the same time (default should be 5)
    # BlockD is the delay between one block and the following one (default 5 seconds)
    # GNU Parallel: Pass $BLOCKN + Sleep $BLOCKD
    boot ${CLUSTERS[${cluster}]}
}

function ncmd()
{
    local nodelist=$1
    if [ -z "${nodelist}" ]; then
        error_exit "ERROR: No domain(s) or node(s) to execute command."
    fi
    shift
    pdsh -w $nodelist $@
}

function nreboot()
{
    local nodelist=$1
    if [ -z "${nodelist}" ]; then
        error_exit "ERROR: No domain(s) or node(s) to reboot."
    fi
    pdsh -w ${nodelist} reboot
}  &>/dev/null

function nshutdown()
{
    local nodelist=$1
    if [ -z "${nodelist}" ]; then
        error_exit "ERROR: No domain(s) or node(s) to shutdown."
    fi
    pdsh -w ${nodelist} systemctl poweroff
}  &>/dev/null

function shutdown_domains()
{
    for domain in ${SELF_ACTIVE_DOMAINS}
    do
        nshutdown ${domain}
    done
    unset domain
}

function shutdown_cluster()
{
    local cluster=$1
    if [ -z "${cluster}" ]; then
        error_exit "ERROR: No cluster to shutdown."
    fi
    nshutdown ${CLUSTERS[${cluster}]}
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
        if (( $NLENG > 0 )); then
            parallel -j $BLOCKN \
            echo "$NPREFIX{}${NET_MGMT[4]}" \; \
            ipmitool -I $IPMI_TYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMI_USER -P $IPMI_PASSWORD power off \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_MGMT[4]}
            ipmitool -I $IPMI_TYPE -H $1${NET_MGMT[4]} -U $IPMI_USER -P $IPMI_PASSWORD power off
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
        if (( $NLENG > 0 )); then
            parallel -j $BLOCKN \
            echo "$NPREFIX{}${NET_MGMT[4]}" \; \
            ipmitool -I $IPMI_TYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMI_USER -P $IPMI_PASSWORD power soft \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_MGMT[4]}
            ipmitool -I $IPMI_TYPE -H $1${NET_MGMT[4]} -U $IPMI_USER -P $IPMI_PASSWORD power soft
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
        if (( $NLENG > 0 )); then
            parallel -j $BLOCKN \
            echo "$NPREFIX{}${NET_MGMT[4]}" \; \
            ipmitool -I $IPMI_TYPE -H "$NPREFIX{}${NET_MGMT[4]}" -U $IPMI_USER -P $IPMI_PASSWORD power reset \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_MGMT[4]}
            ipmitool -I $IPMI_TYPE -H $1${NET_MGMT[4]} -U $IPMI_USER -P $IPMI_PASSWORD power reset
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
        ipmitool -I $IPMI_TYPE -H $1${NET_MGMT[4]} -U $IPMI_USER -P $IPMI_PASSWORD sol deactivate
        sleep 1
        ipmitool -I $IPMI_TYPE -H $1${NET_MGMT[4]} -U $IPMI_USER -P $IPMI_PASSWORD sol activate 1>&3
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

