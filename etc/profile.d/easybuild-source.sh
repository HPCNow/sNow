#!/bin/bash
# This script is part of sNow!
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#set -xv

LOGFILE=/dev/null

if [[ -f ${SNOW_LIB}/common.sh ]]; then
    source ${SNOW_LIB}/common.sh
    get_os_distro
    architecture_identification
fi

if [[ "$(hostname -s)" == "login*" && "$USER" == "snow" ]]; then
    warning_msg "This is the login node, so please don't compile anything here."
    info_msg "Use interative command to run tests and build your code."
fi

PYLIB=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='${SNOW_SOFT}/installation'); "`
export PYTHONPATH=$PYLIB:$PYTHONPATH                                  # eb command needs to find easybuild package
export EASYBUILD_PREFIX=${SNOW_SOFT}/$OS/$OS_VERSION/$ARCHITECTURE        # sets (install|build|source|repository)path
export EASYBUILD_INSTALLPATH=$EASYBUILD_PREFIX                        # path to install the modules and binaries
export EASYBUILD_SOURCEPATH=${SNOW_SOFT}/sources                         # not just the default as shared by all architectures
export EASYBUILD_TMP_LOGDIR=${SNOW_SOFT}/tmp                             # so in shared filesystem not host local
export EASYBUILD_MODULES_TOOL=Lmod                                    # so EB sees exactly the same modules as users
if [[ -e $SNOW_SOFT/modules/all ]]; then
    export MODULEPATH=$(${SNOW_SOFT}/lmod/lmod/libexec/addto --append MODULEPATH $SNOW_SOFT/modules/all)
else
    echo "Easybuild module path is not available"
fi
if [[ -e $EASYBUILD_PREFIX/modules/all ]]; then
    export MODULEPATH=$(${SNOW_SOFT}/lmod/lmod/libexec/addto --append MODULEPATH $EASYBUILD_PREFIX/modules/all)
else
    echo "Applications module path is not available"
fi
