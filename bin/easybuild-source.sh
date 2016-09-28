#!/bin/bash
# This script is part of sNow!
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#set -xv

# The root user will not load this user environment
if [[ $(id -u) -eq 0 ]] ; then
    return
fi

source /sNow/snow-utils/etc/snow.env

# OS release and Service pack discovery 
if [ -f /etc/SuSE-release ]; then
  export OS="SLES"
  export OSVERSION=$(cat /etc/SuSE-release | grep VERSION | cut -f2 -d '=' | sed 's/ //')
  export OSSP=$(/etc/SuSE-release | grep PATCHLEVEL | cut -f2 -d '=' | sed 's/ //')
elif [ -f /etc/fedora-release ]; then
  export OS="FEDORA"
  export OSVERSION=$(cat /etc/fedora-release | sed 's/^.* release \([^\.][^\.]\).*$/\1/')
  export OSSP=""
elif [ -f /etc/redhat-release ]; then
  export OS="RHEL"
  export OSVERSION=$(cat /etc/redhat-release | sed 's/^.* release \([^\.]\).*$/\1/')
  export OSSP=""
elif [ -f /etc/debian_version ]; then
  if [ -f /etc/lsb-release ]; then  
    if [ "z$(grep DISTRIB_ID /etc/lsb-release | cut -f2 -d '=' | sed 's/ //')" = "zUbuntu" ]; then
      export OS="UBUNTU"
      export OSVERSION=$(cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d '=' | sed 's/ //')
      export OSSP=""
    fi
  else
    export OS="DEBIAN"
    export OSVERSION=$(cat /etc/debian_version | cut -f1 -d '.')
    export OSSP=$(cat /etc/debian_version | cut -f2 -d '.')
  fi
elif [ -f /etc/system-release ]; then
  if [ "$(awk -F: '{print $3}' /etc/system-release-cpe)" = "amazon" ]; then
    export OS="AMI"
    export OSVERSION=$(awk -F: '{print $5}' /etc/system-release-cpe)
    export OSSP=""
  fi
else
  export OS="unknown"
fi

if [[ "$(hostname -s)" == "login*" && "$USER" == "snow" ]]; then
    echo "
    This is the login node, so please don't compile anything here.
    Use interative command to run tests and build your code." >&2
fi

# CPU identification 
hex() { printf "0x%X\n" $1; }
CPUDEC=$(lscpu | grep "Model:" | gawk '{print $2}')
CPUHEX=$(hex $CPUDEC)
HARDWARE=$(grep $CPUHEX /sNow/snow-utils/etc/cpu-id-map.conf | gawk '{print $2}')
if [ -z $HARDWARE ]; then
    echo "
    Your CPU model is not recognised. Please consider to add it in  
    /sNow/snow-utils/etc/cpu-id-map.conf 
    and report it to sNow! development Team"
    return
fi

PYLIB=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='/sNow/easybuild/installation'); "`
export PYTHONPATH=$PYLIB:$PYTHONPATH                                  # eb command needs to find easybuild package
export EASYBUILD_PREFIX=$EBPREFIX/$OS/${OSVERSION}${OSSP}/$HARDWARE   # sets (install|build|source|repository)path
export EASYBUILD_INSTALLPATH=$EASYBUILD_PREFIX                        # path to install the modules and binaries
export EASYBUILD_SOURCEPATH=$EBPREFIX/sources                         # not just the default as shared by all architectures
export EASYBUILD_TMP_LOGDIR=$EBPREFIX/tmp                             # so in shared filesystem not host local
export EASYBUILD_MODULES_TOOL=Lmod                                    # so EB sees exactly the same modules as users
export MODULEPATH=$(/usr/share/lmod/lmod/libexec/addto --append MODULEPATH $EASYBUILD_PREFIX/modules/all)
