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

workspace_path_env_name() {
    if [ "${1}" -eq 1 ]; then
        echo "WORKSPACE_PATH"
    else
        echo "WORKSPACE_PATH${1}"
    fi
}

install_override_file() {
    local install_file="${1}"
    local override_file="${2}"
    shift 2
    local fallback_old_file=""

    if [ -f "${override_file}" ]; then
        fallback_old_file="${override_file}"
    else
        for candidate in "$@"; do
            if [ -f "${candidate}" ]; then
                fallback_old_file="${candidate}"
                break
            fi
        done
    fi

    if [ -n "${fallback_old_file}" ]; then
        log_info "Old overwrite file present (${fallback_old_file}), merging..."

        mv -vf "${fallback_old_file}" "${override_file}.old"

        jq -s '.[0] * .[1]' "${override_file}.old" \
            "${install_file}" | tee "${override_file}"
    else
        mv -vf "${install_file}" "${override_file}"
    fi
}
