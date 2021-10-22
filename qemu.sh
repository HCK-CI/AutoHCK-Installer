#!/bin/bash

set -e

install_deps_qemu() {
  log_info "Installing QEMU dependencies"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      sudo apt-get update
      sudo apt-get install -y git make build-essential pkg-config meson zlib1g-dev zlib1g glib2.0 libtool \
        libpixman-1-dev dh-autoreconf bridge-utils libpng-dev libjpeg-dev libsdl2-dev libgtk-3-dev \
        libnfs-dev libseccomp-dev libiscsi-dev libzstd-dev libcurl4-openssl-dev libsdl2-image-dev \
        libkeyutils-dev libfdt-dev libu2f-server-dev libu2f-host-dev libglusterfs-dev librados-dev \
        libncursesw5-dev libspice-protocol-dev libspice-server-dev libusb-dev libusb-1.0-0-dev \
        libusbredirparser-dev libcap-ng-dev libcap-dev libaio-dev
      ;;

    fedora)
      sudo dnf makecache
      sudo dnf install -y git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
        dh-autoreconf bridge-utils libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel \
        libnfs-devel libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
        libfdt-devel libu2f-server-devel libu2f-host-devel libglusterfs-devel librados-devel \
        spice-server-devel libusb-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac
}

compile_qemu() {
  log_info "Compiling QEMU"

  qemu_dir="$(realpath "${1}")"

  (
    cd "${qemu_dir}"

    git clean -f -x
    git clean -f -X
    git clean -f -d

    make distclean || :

    rm -rf build

    git submodule update --init
    ./configure --disable-docs --target-list=x86_64-softmmu --enable-virtfs
    make -j "$(nproc)"
  )
}

check_qemu() {
  qemu_dir="$(realpath "${1}")"

  if [ -d "${qemu_dir}/build" ]; then
    [ -f "${qemu_dir}/build/x86_64-softmmu/qemu-system-x86_64" ] || return 1
    [ -f "${qemu_dir}/build/qemu-img" ] || return 1
    [ -f "${qemu_dir}/build/contrib/ivshmem-server/ivshmem-server" ] || return 1
    [ -f "${qemu_dir}/build/tools/virtiofsd/virtiofsd" ] || return 1
  else
    [ -f "${qemu_dir}/x86_64-softmmu/qemu-system-x86_64" ] || return 1
    [ -f "${qemu_dir}/qemu-img" ] || return 1
    [ -f "${qemu_dir}/ivshmem-server" ] || return 1
    [ -f "${qemu_dir}/virtiofsd" ] || return 1
  fi

  return 0
}

get_config_qemu() {
  qemu_dir="$(realpath "${1}")"

  if [ -d "${qemu_dir}/build" ]; then
    echo "QEMU_BIN='${qemu_dir}/build/x86_64-softmmu/qemu-system-x86_64'"
    echo "QEMU_IMG_BIN='${qemu_dir}/build/qemu-img'"
    echo "IVSHMEM_SERVER_BIN='${qemu_dir}/build/contrib/ivshmem-server/ivshmem-server'"
    echo "FS_DAEMON_BIN='${qemu_dir}/build/tools/virtiofsd/virtiofsd'"
  else
    echo "QEMU_BIN='${qemu_dir}/x86_64-softmmu/qemu-system-x86_64'"
    echo "QEMU_IMG_BIN='${qemu_dir}/qemu-img'"
    echo "IVSHMEM_SERVER_BIN='${qemu_dir}/ivshmem-server'"
    echo "FS_DAEMON_BIN='${qemu_dir}/virtiofsd'"
  fi
}

post_clone_QEMU() {
  log_info "QEMU repository post clone"

  qemu_dir="$(realpath "${1}")"

  install_deps_qemu
  compile_qemu "${qemu_dir}"
  if check_qemu "${qemu_dir}"; then
    log "QEMU binary compiled successfully"
  else
    log_fatal "Can't find QEMU binary"
  fi
}

process_QEMU() {
  log_info "QEMU repository custom processing"

  qemu_dir="$(realpath "${1}")"

  get_config_qemu "${qemu_dir}" >>"${bootstrap}"
  echo >>"${bootstrap}"
}
