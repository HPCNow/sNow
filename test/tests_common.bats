#!/usr/bin/env bats

export SNOW_ROOT=.
source ${SNOW_ROOT}/share/common.sh

@test "valid ip format" {
    valid_ip 8.8.4.4
}

@test "valid ip only nums" {
    ! valid_ip a.8.4.4
}

@test "valid ip less than 255" {
    ! valid_ip 255.255.255.256
}
