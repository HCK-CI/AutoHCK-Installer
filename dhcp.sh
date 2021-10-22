#!/bin/bash

set -e

join_by_comma() { local IFS=","; echo "$*"; }

post_clone_DHCP() {
  log_info "DHCP repository post clone"

  dhcp_dir="$(realpath "${1}")"

  dns_list="$(join_by_comma $(cat /etc/resolv.conf | grep nameserver | grep -e '\.' | cut -d' ' -f2))"
  if [ "${dns_list}" == "127.0.0.53" ]; then
    dns_list="1.1.1.1"
  fi

  config_file="$(bash "${dhcp_dir}/setup.sh" --get-config-file)"

  if [ -f "${config_file}" ]; then
    log_info "DHCP config file found, reconfiguration..."

    sudo bash "${dhcp_dir}/setup.sh" "${net_bridge}" "${net_bridge_subnet}" \
      --config-only "--dns-servers=${dns_list}" --qemu-bin="${QEMU_BIN}"
  else
    log_info "DHCP config file missing, installing..."

    sudo bash "${dhcp_dir}/setup.sh" "${net_bridge}" "${net_bridge_subnet}" \
      --run-test "--dns-servers=${dns_list}" --qemu-bin="${QEMU_BIN}"
  fi
}
