#!/usr/bin/env bats
# Use the default path values unless the environment variables are already setup.
if [[ -z ${SNOW_ROOT} ]]; then
    SNOW_ROOT=/sNow
fi
if [[ -z ${SNOW_HOME} ]]; then
    SNOW_HOME=/home
fi
if [[ -z ${SNOW_BIN} ]]; then
    SNOW_BIN=${SNOW_ROOT}/bin
fi
if [[ -z ${SNOW_SBIN} ]]; then
    SNOW_SBIN=${SNOW_ROOT}/sbin
fi
if [[ -z ${SNOW_ETC} ]]; then
    SNOW_ETC=${SNOW_ROOT}/etc
fi
if [[ -z ${SNOW_LIB} ]]; then
    SNOW_LIB=${SNOW_ROOT}/lib
fi
if [[ -z ${SNOW_SHARE} ]]; then
    SNOW_SHARE=${SNOW_ROOT}/share
fi
if [[ -z ${SNOW_SRV} ]]; then
    SNOW_SRV=${SNOW_ROOT}/srv
fi
if [[ -z ${SNOW_VAR} ]]; then
    SNOW_VAR=${SNOW_ROOT}/var
fi
if [[ -z ${SNOW_LOG} ]]; then
    SNOW_LOG=${SNOW_ROOT}/var/log
fi
if [[ -z ${SNOW_MAN} ]]; then
    SNOW_MAN=${SNOW_ROOT}/man
fi
if [[ -z ${SNOW_TEST} ]]; then
    SNOW_TEST=${SNOW_ROOT}/test
fi
if [[ -z ${SNOW_CONTRIB} ]]; then
    SNOW_CONTRIB=${SNOW_ROOT}/contrib
fi
if [[ -z ${SNOW_EASYBUILD} ]]; then
    SNOW_EASYBUILD=${SNOW_ROOT}/easybuild
fi
if [[ -z ${SNOW_DOC} ]]; then
    SNOW_DOC=${SNOW_ROOT}/doc
fi

readonly LOGFILE=${SNOW_LOG}/snow.log
# shellcheck source=/sNow/lib/common.sh
source "${SNOW_LIB}/common.sh"

@test "valid ip format" {
    valid_ip 8.8.4.4
}

@test "valid ip only nums" {
    ! valid_ip a.8.4.4
}

@test "valid ip less than 255" {
    ! valid_ip 255.255.255.256
}
