#!/bin/bash

set -e

get_distribution() {
    lsb_dist=""

    if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi

    echo "$lsb_dist" | tr '[:upper:]' '[:lower:]'
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

from_env_or_read() {
    env_name="${1}"
    read_msg="${2}"

    if [ -z "${!env_name}" ]; then
        read -r -p "${read_msg}: " value
        echo "${value}"
    else
        read -r -p "${read_msg} [${!env_name}]: " value
        if [ -z "${value}" ]; then
            echo "${!env_name}"
        else
            echo "${value}"
        fi
    fi
}
