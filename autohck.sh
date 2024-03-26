#!/bin/bash

set -e

import_keys() {
  keys=( 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB )
  servers=( hkp://keyserver.ubuntu.com hkp://keys.openpgp.org )

  for server in "${servers[@]}"; do
    gpg2 --keyserver "${server}" --recv-keys "${keys[@]}" && return
  done

  log_warn "Can't load keys from any key servers. Importing keys manually."
  curl -sSL https://rvm.io/mpapis.asc | gpg --import -
  curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
}

install_ruby() {
  log_info "Installing Ruby"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      sudo apt update
      sudo apt -y install tar openssl libssl-dev curl libcurl4 \
        libcurl3-gnutls libcurl4-openssl-dev
      ;;
    centos)
      sudo dnf config-manager --set-enabled crb
      sudo dnf makecache
      # package curl-minimal conflicts with curl provided by curl
      # add '--allowerasing' to command line to replace conflicting packages
      sudo dnf -y --allowerasing install tar openssl openssl-devel curl curl-devel libyaml-devel
      ;;
    rhel)
      sudo dnf makecache
      sudo dnf -y install tar openssl openssl-devel curl curl-devel libyaml-devel
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent tar openssl openssl-devel curl curl-devel
          ;;
        *)
          sudo dnf makecache
          sudo dnf -y install tar openssl openssl-devel curl curl-devel
          ;;
        esac
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please install Ruby manually."
      ;;
  esac

  # get keys from https://rvm.io/
  import_keys

  curl -sSL https://get.rvm.io | bash -s stable

  [ ! -f /etc/profile.d/rvm.sh ] || source /etc/profile.d/rvm.sh
  [ ! -f "${HOME}/.rvm/scripts/rvm" ] || source "${HOME}/.rvm/scripts/rvm"

  rvm install 3.1.3

  gem update --system

  ruby --version
  bundle --version

  curl -Lks 'https://git.io/rg-ssl' | ruby
}

install_deps_autohck() {
  log_info "Installing AutoHCK dependencies"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      sudo apt update
      sudo apt -y install slirp4netns net-tools ethtool xorriso jq ovmf
      ;;
    centos)
      sudo dnf config-manager --set-enabled crb
      sudo dnf makecache
      sudo dnf -y install slirp4netns net-tools ethtool xorriso jq edk2-ovmf
      ;;
    rhel)
      sudo dnf makecache
      sudo dnf -y install slirp4netns net-tools ethtool xorriso jq edk2-ovmf
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent slirp4netns net-tools ethtool xorriso jq edk2-ovmf
          ;;
        *)
          sudo dnf makecache
          sudo dnf -y install slirp4netns net-tools ethtool xorriso jq edk2-ovmf
          ;;
        esac
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac
}

get_fw_config() {
  log_info "Generating OVMF FW config"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      OVMF_CODE='/usr/share/OVMF/OVMF_CODE_4M.fd'

      OVMF_CODE_SB='/usr/share/OVMF/OVMF_CODE_4M.ms.fd'
      OVMF_VARS_SB='/usr/share/OVMF/OVMF_VARS_4M.ms.fd'
      ;;
    centos|rhel|fedora)
      OVMF_CODE='/usr/share/edk2/ovmf-4m/OVMF_CODE.fd'
      if [ ! -f "${OVMF_CODE}" ]; then OVMF_CODE='/usr/share/edk2/ovmf/OVMF_CODE_4M.secboot.qcow2'; fi

      OVMF_CODE_SB='/usr/share/edk2/ovmf-4m/OVMF_CODE.secboot.fd'
      if [ ! -f "${OVMF_CODE_SB}" ]; then OVMF_CODE_SB='/usr/share/edk2/ovmf/OVMF_CODE_4M.qcow2'; fi

      OVMF_VARS_SB='/usr/share/edk2/ovmf-4m/OVMF_VARS.secboot.fd'
      if [ ! -f "${OVMF_VARS_SB}" ]; then OVMF_VARS_SB='/usr/share/edk2/ovmf/OVMF_VARS_4M.secboot.qcow2'; fi

      # RHEL/CentOS and Fedora 34 have different paths
      if [ ! -f "${OVMF_CODE}" ]; then OVMF_CODE='/usr/share/edk2/ovmf/OVMF_CODE.fd'; fi
      if [ ! -f "${OVMF_CODE_SB}" ]; then OVMF_CODE_SB='/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd'; fi
      if [ ! -f "${OVMF_VARS_SB}" ]; then OVMF_VARS_SB='/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd'; fi
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac

  [ -f "${OVMF_CODE}" ] || log_fatal "OVMF_CODE file '$OVMF_CODE' does not exist. Please configure OVMF manually."
  [ -f "${OVMF_CODE_SB}" ] || log_fatal "OVMF_CODE_SB file '$OVMF_CODE_SB' does not exist. Please configure OVMF manually."
  [ -f "${OVMF_VARS_SB}" ] || log_fatal "OVMF_VARS file '$OVMF_VARS_SB' does not exist. Please configure OVMF manually."

  echo "OVMF_CODE='${OVMF_CODE}'"
  echo "OVMF_CODE_SB='${OVMF_CODE_SB}'"
  echo "OVMF_VARS_SB='${OVMF_VARS_SB}'"
}

post_clone_AUTOHCK() {
  log_info "AUTOHCK repository post clone"

  auto_hck_dir="$(realpath "${1}")"

  if ! command_exists ruby; then
    install_ruby
  fi

  commands_to_check=( slirp4netns ifconfig ethtool xorriso jq )
  for cmd_to_check in "${commands_to_check[@]}"; do
    command_exists "${cmd_to_check}" || install_deps_autohck
    command_exists "${cmd_to_check}" || log_fatal "${cmd_to_check} command does not exist"
  done

  get_fw_config >>"${bootstrap}"
  echo >>"${bootstrap}"

  (
    cd "${auto_hck_dir}"
    bundle config path vendor/bundle
    bundle install --retry=32
  )
}
