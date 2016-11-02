#!/bin/bash
# This script is part of sNow!
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow
#set -xv

# The root user will not load this user environment
#if [[ $(id -u) -eq 0 ]] ; then
#    exit # return
#fi

SNOW_PATH=/sNow
SNOW_SOFT=$SNOW_PATH/easybuild
SNOW_TOOL=$SNOW_PATH/snow-tools
LOGFILE=/dev/null

if [[ -f ${SNOW_TOOL}/share/common.sh ]]; then
    source ${SNOW_TOOL}/share/common.sh
    get_os_distro
    architecture_identification
fi

if [[ "$(hostname -s)" == "login*" && "$USER" == "snow" ]]; then
    echo "
    This is the login node, so please don't compile anything here.
    Use interative command to run tests and build your code." >&2
fi

PYLIB=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='${SNOW_SOFT}/installation'); "`
export PYTHONPATH=$PYLIB:$PYTHONPATH                                  # eb command needs to find easybuild package
export EASYBUILD_PREFIX=${SNOW_SOFT}/$OS/$OSVERSION/$ARCHITECTURE        # sets (install|build|source|repository)path
export EASYBUILD_INSTALLPATH=$EASYBUILD_PREFIX                        # path to install the modules and binaries
export EASYBUILD_SOURCEPATH=${SNOW_SOFT}/sources                         # not just the default as shared by all architectures
export EASYBUILD_TMP_LOGDIR=${SNOW_SOFT}/tmp                             # so in shared filesystem not host local
export EASYBUILD_MODULES_TOOL=Lmod                                    # so EB sees exactly the same modules as users
export MODULEPATH=$(${SNOW_SOFT}/lmod/lmod/libexec/addto --append MODULEPATH $EASYBUILD_PREFIX/modules/all)
