#!/bin/bash
# These are the common functions which may be used by sNow! Command Line Interface 
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#

function error_exit()
{
    local e_msg="${1:-'Unknown Error: Please report the issue to https://bitbucket.org/hpcnow/snow-tools/issues'}"
    tput cuu 1 && tput el
    printf "\r\e[0K[\e[0;31m%c\e[m] %s \e[0;31m\e[m \n\n" "E" "${e_msg}" 1>&2
    exit 1
}

function error_msg()
{
    local e_msg="${1}"
    tput cuu 1 && tput el
    printf "\r\e[0K[\e[0;31m%c\e[m] %s \e[0;31m\e[m \n\n" "E" "${e_msg}" 1>&2
}

function warning_msg()
{
    local w_msg="${1}"
    tput cuu 1 && tput el
    printf "\r\e[0K[\e[0;38;5;208m%c\e[m] %s \e[0;32m\e[m \n\n" "W" "${w_msg}" 1>&2
}

function info_msg()
{
    local i_msg="${1}"
    tput cuu 1 && tput el
    printf "\r\e[0K[\e[0;32m%c\e[m] %s \e[0;32m\e[m \n\n" "I" "${i_msg}" 1>&2
}

function logsetup()
{
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
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
        tput cuu 1 && tput el
        printf "\r\e[0K[\e[0;32m%c\e[m] %s\n" "$spinstr" "$2" 
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
}

function error_check()
{
    local status=$1
    tput cuu 1 && tput el
    if [ $status -eq 0 ]; then
        printf "\r\e[0K[\e[0;32m%c\e[m] %s \e[0;32m%s\e[m \n" "*" "$2" "OK"
    else
        printf "\r\e[0K[\e[0;31m%c\e[m] %s \e[0;31m%s\e[m \n" "!" "$2" "FAIL"
    fi
}

function shelp()
{
    cat <<- EOF 
    This is the sNow! Command Line Interface
    Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
    For more information, visit the official website : www.hpcnow.com

    Usage: snow [function] <option|domain|server>

    Function List:

        * init                              | setup the system according to the parameters defined in snow.conf and active-domains.conf
        * config                            | shows the sNow! configuration based on the changes applied in snow.conf and domains.conf
        * update tools                      | updates the sNow! Tools 
        * update configspace                | updates configuration files from private git 
        * update template                   | updates the sNow! image used to create new domains
        * deploy <domain|server> <template> | deploy specific domain/server (optional: with specific template) 
        * clone <server> <image>            | creates a PXE image to boot the compute nodes diskless
        * remove <domain>                   | removes an existing domain deployed with sNow!
        * list <all>                        | list current domains (services) and their status
        * boot <domain|server> <image>      | boot specific domain or server with optional image
        * boot domains                      | boot all the domains (all services not available under sNow! HA)
        * boot cluster <cluster> <image>    | boot all the compute nodes of the selected cluster (by default 20 nodes at once)
        * reboot <domain|server>            | reboot specific domain or server
        * shutdown <domain|server>          | shutdown specific domain or server
        * shutdown cluster <cluster>        | shutdown all the compute nodes of the selected cluster
        * destroy <domain|server>           | force to stop specific domain or server
        * reset <domain|server>             | force to reboot specific domain or server
        * poweroff <domain|server>          | force to shutdown specific domain or server simulating a power button press
        * console <domain|server>           | console access to specific domain or server
        * uptime <domain|sever>             | shows uptime of specific domain or server
        * cmd <domain|sever> <command>      | executes a command in the domain(s) or server(s)

    Examples:

        snow update tools
        snow deploy ldap01
        snow cmd n[001-999] uname
EOF
}

function end_msg()
{
    cat <<- EOF 
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
EOF
}

function config()
{
if [[ ! -f ${SNOW_DOMAINS} ]]; then
    echo "No ${SNOW_DOMAINS} found"
else
    cat ${SNOW_PATH}/snow-tools/etc/snow.conf
    echo "==== Active Domains ===="
    cat ${SNOW_PATH}/snow-tools/etc/active-domains.conf | grep -v "^#" |  gawk '{print $0}'
fi
}

function download() 
{
    case $DOWNLD in
        axel) 
            axel -q -n 10 $1 -o $2 
        ;;
        wget)
            wget -q -P $2 $1
        ;;
        *) 
            error_exit "Error: $DOWNLD is not supported"
        ;;
    esac
}

function bkp()
{
    bkpfile=$1
    next=$(date +%Y%m%d%H%M)
    if [[ -e $bkpfile ]]; then 
        cp -pr $bkpfile $bkpfile.$next-snow
    fi
}

function hex()
{
    #transforms the provided value to hexa
    printf "0x%X\n" $1;
}

function architecture_identification() 
{
    cpudec=$(lscpu | grep "Model:" | gawk '{print $2}')
    cpuhex=$(hex $cpudec)
    architecture=$(grep $cpuhex ${SNOW_TOOL}/etc/cpu-id-map.conf | gawk '{print $2}')
    if [ -z $architecture ]; then
        warning_msg "Your CPU model is not recognised. Please consider to add it in the  
        ${SNOW_TOOL}/etc/cpu-id-map.conf and report it to sNow! development Team"
    else
        export ARCHITECTURE=$architecture
    fi
}

function is_golden_node()
{
    # Returns 0 if this node is a golden node
    gn=1
    for i in "${GOLDEN_NODES[@]}"
    do
        if [[ "$(hostname -s)" == "$i" ]]; then 
            gn=0
        fi
    done
    return $gn
} 1>>$LOGFILE 2>&1

function get_os_distro()
{
    # OS release and Service pack discovery 
    lsb_dist=$(lsb_release -si 2>&1 | tr '[:upper:]' '[:lower:]' | tr -d '[[:space:]]')
    dist_version=$(lsb_release -sr 2>&1 | tr '[:upper:]' '[:lower:]' | tr -d '[[:space:]]')
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
    repo=$1
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
}

function add_repos()
{
    repos=$1
    for repo in $(cat $repos); do
        if [[ ! -z $repo ]]; then
            add_repo $repo
        fi
    done
}


function install_software()
{
    pkgs=$1
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
    prefix=$1;
    shift=$(( 32 - prefix ));
    bitmask=""
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
    bitmask=$1;
    wildcard_mask=
    for octet in $bitmask; do
        wildcard_mask="${wildcard_mask} $(( 255 - 2#$octet ))"
    done
    echo $wildcard_mask;
}

function mask2cidr()
{
    nbits=0
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
    ip=$1
    host_extension=$2
    net=$(echo $ip | cut -d '/' -f 1);
    prefix=$(echo $ip | cut -d '/' -f 2);
    if [[ $prefix =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        cidr=$(mask2cidr $prefix)
    else
        cidr=$prefix
    fi
    bit_netmask=$(prefix_to_bit_netmask $cidr);
    wildcard_mask=$(bit_netmask_to_wildcard_netmask "$bit_netmask");
    str=
    for (( i = 1; i <= 4; i++ )); do
        range=$(echo $net | cut -d '.' -f $i)
        mask_octet=$(echo $wildcard_mask | cut -d ' ' -f $i)
        if [ $mask_octet -gt 0 ]; then
            range="{$range..$(( $range | $mask_octet ))}";
        fi
        str="${str} $range"
    done
    ips=$(echo $str | sed "s, ,\\.,g"); 
    hostip=( $(eval echo $ips | tr ' ' '\n') )
    if (( "${#host[@]}" > "${#hostip[@]}" )); then
        error_exit "Error: the /etc/hosts can NOT be generated because the IP rank is too short!"
    fi
    for (( i=0; i<${#host[@]}; i++ ));
    do 
        printf "%s %20s\n" "${hostip[$i]}" "${host[$i]}$host_extension"
    done
}


function init()
{
    # Check for snow.conf
    if [[ ! -f ${SNOW_CONF}/system_files/etc/snow.conf ]]; then
        ln -s ${SNOW_CONF}/system_files/etc/snow.conf ${SNOW_TOOL}/etc/snow.conf
    elif [[ -f ${SNOW_TOOL}/etc/snow.conf ]]; then
        mv ${SNOW_TOOL}/etc/snow.conf ${SNOW_CONF}/system_files/etc/snow.conf
        ln -s ${SNOW_CONF}/system_files/etc/snow.conf ${SNOW_TOOL}/etc/snow.conf
    else
        error_exit "The snow.conf is not yet available."
    fi
    # Check for active-domains.conf 
    if [[ ! -f ${SNOW_CONF}/system_files/etc/active-domains.conf ]]; then
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
    elif [[ ! -e ${SNOW_TOOL}/etc/domains.conf ]]; then
        cat ${SNOW_TOOL}/etc/domains.conf-example > ${SNOW_TOOL}/etc/domains.conf
        gawk -v brdmz=${NET_DMZ[0]} -v gwdmz=${NET_DMZ[1]} -v netdmz=${NET_DMZ[2]} -v maskdmz=${NET_DMZ[3]} \
             -v brsnow=${NET_SNOW[0]} -v gwsnow=${NET_SNOW[1]} -v netsnow=${NET_SNOW[2]} -v masksnow=${NET_SNOW[3]} \
            'BEGIN{i=0}{
                if ($1 !~ /^#/){
                    i=i+1
                    printf "%12s\t %20s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s %6s %16s %9s 76:fd:31:9e:%02i:%2s %16s %16s \n", $1, $2, "eth0", netsnow""i, brsnow, i, "01", masksnow, gwsnow, "eth1", netdmz""i, brdmz, i, "02", maskdmz, gwdmz  
                }
            }' ${SNOW_ACTIVE_DOMAINS} >> ${SNOW_CONF}/system_files/etc/domains.conf
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
    generate_hostlist ${NET_IPMI[2]}100/${NET_IPMI[3]} "${NET_IPMI[4]}" >> /etc/hosts
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
            error_exit "The domain $1 already exist, please use force option to overwrite the domain"
        else
            FORCE="--force"
        fi
    else
        IMG_STATUS=$(cat ${SNOW_DOMAINS} | grep "$opt2")
        if [[ ! $IMG_STATUS ]]; then
            error_exit "The domain $1 is NOT available in the ${SNOW_DOMAINS}."
        else
            info_msg "Deploying the domain $1. It can take few minutes. Please wait!"
        fi
    fi

    if [[ -n "$IMG_DST" ]]; then
        IMG_DST_OPT="--${IMG_DST}"
    fi 
    cat ${SNOW_DOMAINS} | grep "$opt2" | gawk -v force="$FORCE" -v img_dst=$IMG_DST_OPT -v pwd=$MASTERPWD '{
        hostname=$1; role=$2; dev_nic1=$3; ip_nic1=$4; bridge_nic1=$5; mac_nic1=$6; mask_nic1=$7; gw_nic1=$8
        }
        END{
        system("xen-create-image --config=/sNow/snow-tools/etc/xen-tools.conf --roledir=/sNow/snow-tools/etc/role.d --hostname="hostname" --mac="mac_nic1" --bridge="bridge_nic1" --ip="ip_nic1" --gateway="gw_nic1" --netmask="mask_nic1" --role=snow,"role" --copyhosts --password="pwd " "force" "img_dst)
        }' || error_exit "ERROR: unable to install the domain, please report the issue to HPCNow!"
    second_nic=$(gawk -v guest=$opt2 '{if($1 == guest){print $10}}' ${SNOW_DOMAINS}) 
    if [[ "$second_nic" != "none" && -e ${SNOW_TOOL}/etc/domains/$opt2.cfg ]]; then 
        guest_network=$(gawk -v guest=$opt2 '{if($1 == guest){print "vif        = [ '\''ip="$4", mac="$6", bridge="$5"'\'', '\''ip="$10", mac="$12", bridge="$11"'\'' ]"}}' ${SNOW_DOMAINS})
        gawk -v gnet="$guest_network" '{if($1 == "vif"){print gnet}else{print $0}}' ${SNOW_TOOL}/etc/domains/$opt2.cfg > ${SNOW_TOOL}/etc/domains/$opt2.cfg.extended
        mv ${SNOW_TOOL}/etc/domains/$opt2.cfg.extended ${SNOW_TOOL}/etc/domains/$opt2.cfg
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
    for i in $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
    do 
        cp -p ${SNOW_CONF}/boot/pxelinux.cfg/$1 ${SNOW_CONF}/boot/pxelinux.cfg/$(gethostip $NPREFIX$i | gawk '{print $3}')
    done
}

function deploy()
{
    if [[ -z "$1" ]]; then
        error_exit "ERROR: No domain or node to deploy"
    fi
    get_server_distribution $1
    warning_msg "This will install $1. All the data contained in these nodes will be removed"
    #read -p "Are you sure? (y/n) : " -n 1 -r
    #echo 
    #if [[ $REPLY =~ ^[Yy]$ ]]
    #then
        if (($IS_VM)) ; then
            xen_create $1 $2
        else
            node_rank $1
            #BLOCKN=${2:-$BLOCKN}
            #BLOCKD=${3:-$BLOCKD}
            DEFAULT_TEMPLATE=${2:-$DEFAULT_TEMPLATE}
            if ! [[ -f ${SNOW_CONF}/boot/pxelinux.cfg/$DEFAULT_TEMPLATE ]] ; then
                error_exit "No template $DEFAULT_TEMPLATE available in ${SNOW_CONF}/boot/pxelinux.cfg"
            fi
            if (( $NLENG > 0 )); then
                info_msg "Deploying node range $1 ... This will take a while, Please wait"
                #parallel -j $BLOCKN snow check_host_status "$NPREFIX{}${NET_IPMI[4]}" ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
                boot_copy $DEFAULT_TEMPLATE
                parallel -j $BLOCKN \
                echo "Deploying node : $NPREFIX{} ... Please wait" \; \
                ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_IPMI[4]}" -U $IPMIUSER -P $IPMIPWD power reset \; \
                sleep 5 \; \
                ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_IPMI[4]}" -U $IPMIUSER -P $IPMIPWD power on \; \
                sleep $BLOCKD \
                ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
                sleep $BOOT_DELAY
                info_msg "Setting up disk as boot device... Please wait"
                boot_copy $DEFAULT_BOOT
            else
                check_host_status $1${NET_IPMI[4]}
                cp -p ${SNOW_CONF}/boot/pxelinux.cfg/$DEFAULT_TEMPLATE ${SNOW_CONF}/boot/pxelinux.cfg/$(gethostip $1 | gawk '{print $3}')
                ipmitool -I $IPMITYPE -H $1${NET_IPMI[4]} -U $IPMIUSER -P $IPMIPWD power reset
                sleep 5
                ipmitool -I $IPMITYPE -H $1${NET_IPMI[4]} -U $IPMIUSER -P $IPMIPWD power on
                info_msg "Deploying node : $1 ... Please wait"
                sleep $BOOT_DELAY
                cp -p ${SNOW_CONF}/boot/pxelinux.cfg/$DEFAULT_BOOT ${SNOW_CONF}/boot/pxelinux.cfg/$(gethostip $1 | gawk '{print $3}') 
            fi
        fi
    #else
    #    echo
    #    echo "Well done. It's better to be sure."
    #fi
} # 1>>$LOGFILE 2>&1

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
            cp -p /boot/initrd.img-$(uname -r) ${SNOW_CONF}/boot/image/$IMAGE/
            cp -p /boot/vmlinuz-$(uname -r) ${SNOW_CONF}/boot/image/$IMAGE/
            generate_rootfs $IMAGE
        ;;
        rhel|redhat|centos)
            dracut -a "nfs network base" --host-only -f ${SNOW_CONF}/boot/image/$IMAGE/initrd-$(uname -r).img $(uname -r) root=dhcp 
            cp -p /boot/vmlinuz-$(uname -r) ${SNOW_CONF}/boot/image/$IMAGE/
            generate_rootfs $IMAGE
       ;;
       suse|sle[sd]|opensuse)
           kiwi --root / --add-profile netboot --type pxe -d ${SNOW_CONF}/boot/image/$IMAGE
           mv initrd-netboot-*.gz initrd-$(uname -r)
           mv initrd-netboot-*.kernel linux-$(uname -r)
           mv *x86_64* root.gz
       ;;
   esac
}

function hooks()
{
    hooks_path=$1
    HOOKS=$(ls -1 ${hooks_path}/??-*.sh)
    for hook in $HOOKS
    do
        if [[ -x "$hook" ]]; then
            $hook && error_check 0 "Running hook : $hook " || error_check 1 "Running hook error : $hook " &
            spinner $!             "Running hook : $hook "
        else
            warning_msg "File '$hook' is not executable. If you want to run it, do : chmod 750 $hook"
        fi
    done
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
    # rootfs size in megabytes
    rootfs_size="4096"
    # set mount point for the rootfs
    mount_point="rootfs-loop"
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
    hooks ${SNOW_CONF}/boot/images/$IMAGE
    first_boot_hooks ${SNOW_CONF}/boot/images/$IMAGE
    # * if local scratch disk /tmp
    patch_network_configuration

    umount ${mount_point}
    gzip -c rootfs | dd of=${SNOW_CONF}/boot/image/$IMAGE/rootfs.gz
    # create PXE boot configuration
    sed -e "s|__IMAGE__|$IMAGE|" ${SNOW_TOOL}/etc/config_template.d/boot/pxelinux.cfg/diskless > ${SNOW_CONF}/boot/pxelinux.cfg/$IMAGE
}

function clone()
{
    NODE=$1
    IMAGE=$2
    if [[ -z "$NODE" ]]; then
        error_exit "ERROR: no node name to clone is provided"
    fi
    if [[ -z "$IMAGE" ]]; then
        error_exit "ERROR: no name is provided for the image"
    fi
    # Check if snow CLI is executed in the same golden node or from the snow server
    if [[ "$(uname -n)" == "$NODE" ]]; then
        if [[ -f ${SNOW_CONF}/boot/image/$IMAGE/rootfs.gz ]]; then
            warning_msg "This will overwrite the image $IMAGE"
        else
            warning_msg "This will clone $NODE and generate the image $IMAGE."
        fi
        get_server_distribution $NODE
        check_host_status $1${NET_IPMI[4]}
        generate_pxe_image $IMAGE
    else
        ssh $NODE $0 clone $@
    fi
}

function list()
{
    xl list $opt2
}

function avail_domains()
{
    LC_ALL=C xen-list-images --test /sNow/snow-tools/etc/domains
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
                xl create ${SNOW_PATH}/snow-tools/etc/domains/${1}${DOM_EXT}.cfg
            else
                warning_msg "The domain $1 is already runnning"
            fi
        else
            error_msg "The domain $1 needs to be deployed first: Execute : snow deploy $1"
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
            echo "$NPREFIX{}${NET_IPMI[4]}" \; \
            sleep $BLOCKD \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_IPMI[4]}" -U $IPMIUSER -P $IPMIPWD power on \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else 
            check_host_status $1${NET_IPMI[4]}
            ipmitool -I $IPMITYPE -H $1${NET_IPMI[4]} -U $IPMIUSER -P $IPMIPWD power on
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
        IS_VM=$(cat ${SNOW_DOMAINS} | gawk -v vm="$1" 'BEGIN{isvm=0}{if (match($1, vm)){isvm=1}}END{print isvm}')
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
            echo "$NPREFIX{}${NET_IPMI[4]}" \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_IPMI[4]}" -U $IPMIUSER -P $IPMIPWD power off \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_IPMI[4]}
            ipmitool -I $IPMITYPE -H $1${NET_IPMI[4]} -U $IPMIUSER -P $IPMIPWD power off
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
            echo "$NPREFIX{}${NET_IPMI[4]}" \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_IPMI[4]}" -U $IPMIUSER -P $IPMIPWD power soft \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_IPMI[4]}
            ipmitool -I $IPMITYPE -H $1${NET_IPMI[4]} -U $IPMIUSER -P $IPMIPWD power soft
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
            echo "$NPREFIX{}${NET_IPMI[4]}" \; \
            ipmitool -I $IPMITYPE -H "$NPREFIX{}${NET_IPMI[4]}" -U $IPMIUSER -P $IPMIPWD power reset \
            ::: $(eval echo "{${NRANK[0]}..${NRANK[1]}}")
        else
            check_host_status $1${NET_IPMI[4]}
            ipmitool -I $IPMITYPE -H $1${NET_IPMI[4]} -U $IPMIUSER -P $IPMIPWD power reset
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
        xl console $1
    else
        check_host_status $1${NET_IPMI[4]}
        ipmitool -I $IPMITYPE -H $1${NET_IPMI[4]} -U $IPMIUSER -P $IPMIPWD sol deactivate
        sleep 1
        ipmitool -I $IPMITYPE -H $1${NET_IPMI[4]} -U $IPMIUSER -P $IPMIPWD sol activate
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

# Load additional functions in ${SNOW_TOOL}/etc/common.d
if [ -d ${SNOW_TOOL}/etc/common.d ]; then
  for i in ${SNOW_TOOL}/etc/common.d/*.sh; do
    if [ -r $i ]; then
      source $i
    fi
  done
  unset i
fi

# Load additional functions in ${SNOW_TOOL}/etc/hooks.d
if [ -d ${SNOW_TOOL}/etc/hooks.d ]; then
  for i in ${SNOW_TOOL}/etc/hooks.d/*.sh; do
    if [ -r $i ]; then
      source $i
    fi
  done
  unset i
fi

