#!/bin/csh 
# This script is part of sNow!
# Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
# For more information, visit the official website : www.hpcnow.com/snow

# The root user will not load this user environment
#if ($?USER) then
#    exit
#endif

setenv SNOW_ROOT "/sNow"
setenv SNOW_SOFT "$SNOW_ROOT/easybuild"
setenv SNOW_ROOT "$SNOW_ROOT/snow-tools"
setenv LOGFILE   "/dev/null"

if ( -f ${SNOW_ROOT}/share/common.sh ) then
    bash -c "source ${SNOW_ROOT}/share/common.sh ; get_os_distro; architecture_identification; exec csh"
endif

if ( "`hostname -s`" == "login*" && "$USER" == "snow" ) then
    echo "
    This is the login node, so please don't compile anything here.
    Use interative command to run tests and build your code." >&2
endif

setenv PYLIB `python -c "import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='${SNOW_SOFT}/installation'); "`
#setenv PYTHONPATH "$PYLIB:$PYTHONPATH"                                  # eb command needs to find easybuild package
setenv PYTHONPATH "$PYLIB"                                  # eb command needs to find easybuild package
setenv EASYBUILD_PREFIX "$SNOW_SOFT/$OS/$OS_VERSION/$ARCHITECTURE"        # sets (install|build|source|repository)path
setenv EASYBUILD_INSTALLPATH "$EASYBUILD_PREFIX"                        # path to install the modules and binaries
setenv EASYBUILD_SOURCEPATH "$SNOW_SOFT/sources"                         # not just the default as shared by all architectures
setenv EASYBUILD_TMP_LOGDIR "$SNOW_SOFT/tmp"                             # so in shared filesystem not host local
setenv EASYBUILD_MODULES_TOOL "Lmod"                                    # so EB sees exactly the same modules as users
if ( -d $EASYBUILD_PREFIX/modules/all ) then
    setenv MODULEPATH `${SNOW_SOFT}/lmod/lmod/libexec/addto --append MODULEPATH $EASYBUILD_PREFIX/modules/all`
endif
