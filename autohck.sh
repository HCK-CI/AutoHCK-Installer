#!/bin/bash

set -e

install_ruby() {
  log_info "Installing Ruby"

  # get keys from https://rvm.io/
  gpg2 --recv-keys \
    409B6B1796C275462A1703113804BB82D39DC0E3 \
    7D2BAF1CF37B13E2069D6956105BD0E739499BDB

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      sudo apt update
      sudo apt -y install tar openssl libssl-dev curl libcurl4 \
        libcurl3-gnutls libcurl4-openssl-dev
      ;;

    fedora)
      sudo dnf makecache
      sudo dnf -y install tar openssl openssl-devel curl curl-devel
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please install Ruby manually."
      ;;
  esac

  curl -sSL https://get.rvm.io | bash -s stable

  [ ! -f /etc/profile.d/rvm.sh ] || source /etc/profile.d/rvm.sh
  [ ! -f "${HOME}/.rvm/scripts/rvm" ] || source "${HOME}/.rvm/scripts/rvm"

  rvm install 3.0.4

  if [ has_openssl_3 ]; then
    log_info "You system use OpenSSL 3.x. This version is not fully supported by ruby. " \
      "Installing OpenSSL gem for SSL support."
    curl -L https://rubygems.org/downloads/openssl-3.0.0.gem -o /tmp/openssl-3.0.0.gem
    gem install /tmp/openssl-3.0.0.gem
  fi

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
      sudo apt -y install net-tools ethtool bridge-utils mkisofs jq
      ;;

    fedora)
      sudo dnf makecache
      sudo dnf -y install net-tools ethtool bridge-utils genisoimage jq
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac
}

post_clone_AUTOHCK() {
  log_info "AUTOHCK repository post clone"

  auto_hck_dir="$(realpath "${1}")"

  if ! command_exists ruby; then
    install_ruby
  fi

  commands_to_check=( ifconfig ethtool brctl mkisofs jq )
  for cmd_to_check in "${commands_to_check[@]}"; do
    command_exists "${cmd_to_check}" || install_deps_autohck
    command_exists "${cmd_to_check}" || log_fatal "${cmd_to_check} command does not exist"
  done

  (
    cd "${auto_hck_dir}"
    bundle config path vendor/bundle
    bundle install --retry=32
  )
}
