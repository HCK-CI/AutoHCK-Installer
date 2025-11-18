#!/bin/bash

set -e

get_distribution() {
    lsb_dist=""

    if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi

    echo "$lsb_dist" | tr '[:upper:]' '[:lower:]'
}

get_distribution_variant() {
  variant=""

  if [ -r /etc/os-release ]; then
    variant="$(. /etc/os-release && echo "$VARIANT_ID")"
  fi

  echo "$variant" | tr '[:upper:]' '[:lower:]'
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

from_env_or_read() {
    local env_name="${1}"
    local read_msg="${2}"
    local value
    local default_value="${!env_name}"

    if [ "${INSTALL_SILENT}" == "true" ]; then
        echo "${default_value}"
        return
    fi

    if [ -n "${default_value}" ]; then
        read -r -p "${read_msg} [${default_value}]: " value
        if [ -z "${value}" ]; then
            echo "${default_value}"
        else
            echo "${value}"
        fi
    else
        read -r -p "${read_msg}: " value
        echo "${value}"
    fi
}

has_openssl_3() {
    local openssl_version="$(openssl version 2>/dev/null || true)"
    [[ $openssl_version = "OpenSSL 3"?* ]]
}

is_redefined_by_file() {
    var_name="${1}"
    file="${2}"

    var_value1="${!var_name}"
    var_value2="$(source "${file}"; echo "${!var_name}")"

    [[ "${var_value1}" != "${var_value2}" ]]
}
