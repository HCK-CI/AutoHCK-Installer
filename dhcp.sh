#!/bin/bash

set -e

join_by_comma() { local IFS=","; echo "$*"; }

post_clone_DHCP() {
  log_info "DHCP repository post clone"

  dhcp_dir="$(realpath "${1}")"

  resolv_confs=("/etc/resolv.conf" "/usr/lib/systemd/resolv.conf" "/run/systemd/resolve/resolv.conf")
  for resolv_conf in ${resolv_confs[@]}; do
    log_info "Processing DNS servers from ${resolv_conf}"
    dns_list="$(join_by_comma $(cat "${resolv_conf}" | grep nameserver | grep -e '\.' | cut -d' ' -f2))"
    if [ "${dns_list}" == "127.0.0.53" ]; then
      continue
    fi
  done

  if [ "${dns_list}" == "127.0.0.53" ]; then
    log_warn "DNS servers were not found, using defaults"
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
