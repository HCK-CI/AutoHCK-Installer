#!/bin/bash

set -e

RUBY_VERSION=3.3.7

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
          rpm-ostree install -A --allow-inactive --idempotent tar openssl openssl-devel curl curl-devel gcc libyaml-devel
          ;;
        *)
          sudo dnf makecache
          sudo dnf -y install tar openssl openssl-devel curl curl-devel gcc libyaml-devel
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

  rvm install "${RUBY_VERSION}"

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
      sudo apt -y install slirp4netns net-tools ethtool xorriso jq
      ;;
    centos)
      sudo dnf config-manager --set-enabled crb
      sudo dnf makecache
      sudo dnf -y install slirp4netns net-tools ethtool xorriso jq
      ;;
    rhel)
      sudo dnf makecache
      sudo dnf -y install slirp4netns net-tools ethtool xorriso jq
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent slirp4netns net-tools ethtool xorriso jq
          ;;
        *)
          sudo dnf makecache
          sudo dnf -y install slirp4netns net-tools ethtool xorriso jq
          ;;
        esac
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
  else
    result=$(ruby -e "puts Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('${RUBY_VERSION}')")
    if [ "x${result}" != "xtrue" ]; then
      log_warn "Ruby version is less than ${RUBY_VERSION}"
      if command_exists rvm; then
        log_info "Installing Ruby using rvm"
        install_ruby
      else
        log_error "rvm command does not exist. AutoHCK Installer does not support installation of Ruby without rvm."
        log_fatal "Please install Ruby version ${RUBY_VERSION} or greater manually."
      fi
    else
      log_info "Ruby version is ${RUBY_VERSION} or greater"
    fi
  fi

  commands_to_check=( slirp4netns ifconfig ethtool xorriso jq )
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

process_AUTOHCK() {
  log_info "AUTOHCK repository custom processing"

  echo >>"${bootstrap}"
}
