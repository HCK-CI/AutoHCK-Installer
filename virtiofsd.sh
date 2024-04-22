#!/bin/bash

set -e

install_deps_virtiofsd() {
  log_info "Installing virtiofsd dependencies"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      sudo apt-get update
      sudo apt-get install -y libcap-ng-dev libseccomp-dev build-essential curl
      ;;
    centos)
      sudo dnf config-manager --set-enabled crb
      sudo dnf makecache
      sudo dnf --allowerasing install -y libcap-ng-devel libseccomp-devel gcc curl
      ;;
    rhel)
      sudo dnf makecache
      sudo dnf install -y libcap-ng-devel libseccomp-devel gcc curl
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent libcap-ng-devel libseccomp-devel gcc curl
          ;;
        *)
          sudo dnf makecache
          sudo dnf install -y libcap-ng-devel libseccomp-devel gcc curl
          ;;
        esac
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac
}

install_virtiofsd_package() {
  log_info "Installing virtiofsd package"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      sudo apt-get update
      sudo apt-get install -y virtiofsd
      ;;
    rhel|centos)
      sudo dnf makecache
      sudo dnf install -y virtiofsd
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent virtiofsd
          ;;
        *)
          sudo dnf makecache
          sudo dnf install -y virtiofsd
          ;;
        esac
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac
}

install_rust() {
  log_info "Installing Rust"

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y -v

  source "$HOME/.cargo/env"

  cargo --version
}

compile_virtiofsd() {
  log_info "Compiling virtiofsd"

  virtiofsd_dir="$(realpath "${1}")"

  (
    cd "${virtiofsd_dir}"

    cargo build --release
  )
}

check_virtiofsd() {
  virtiofsd_dir="$(realpath "${1}")"

  [ -f "${virtiofsd_dir}/target/release/virtiofsd" ] || return 1

  return 0
}

get_config_virtiofsd_repo() {
  virtiofsd_dir="$(realpath "${1}")"

  echo "FS_DAEMON_BIN='${virtiofsd_dir}/target/release/virtiofsd'"
}

get_config_virtiofsd_package() {
  FS_DAEMON_BIN='/usr/libexec/virtiofsd'

  [ -f "${FS_DAEMON_BIN}" ] || log_fatal "FS_DAEMON_BIN file '$FS_DAEMON_BIN' does not exist. Please configure virtiofsd manually."

  echo "FS_DAEMON_BIN='${FS_DAEMON_BIN}'"
}

post_clone_VIRTIOFSD() {
  log_info "VIRTIOFSD repository post clone"

  virtiofsd_dir="$(realpath "${1}")"

  install_deps_virtiofsd

  if ! command_exists rustc || ! command_exists cargo; then
    install_rust
  fi

  compile_virtiofsd "${virtiofsd_dir}"
  if check_virtiofsd "${virtiofsd_dir}"; then
    log "VIRTIOFSD binary compiled successfully"
  else
    log_fatal "Can't find VIRTIOFSD binary"
  fi
}

process_VIRTIOFSD() {
  log_info "VIRTIOFSD dependency custom processing"

  virtiofsd_package="${2}"

  if [ "x${virtiofsd_package}" == "x" ]; then
    virtiofsd_dir="$(realpath "${1}")"
    get_config_virtiofsd_repo "${virtiofsd_dir}" >>"${bootstrap}"
  else
    install_virtiofsd_package
    get_config_virtiofsd_package >>"${bootstrap}"
  fi

  echo >>"${bootstrap}"
}
