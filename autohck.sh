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
      sudo apt -y install tar
      ;;

    fedora)
      sudo dnf makecache
      sudo dnf -y install tar
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac

  curl -sSL https://get.rvm.io | bash -s stable

  source /etc/profile.d/rvm.sh
  rvm install 3.0

  gem update --system

  ruby --version
  bundle --version

  curl -Lks 'https://git.io/rg-ssl' | ruby
}

run_bundle() {
  if [ "$(id -u)" == "0" ]; then
    bundle "$*"
  else
    rvmsudo bundle "$*" || sudo bundle "$*"
  fi
}

post_clone_AUTOHCK() {
  log_info "AUTOHCK repository post clone"

  auto_hck_dir="$(realpath "${1}")"

  if ! command_exists ruby; then
    install_ruby
  fi

  (
    cd "${auto_hck_dir}"
    run_bundle install
  )
}
