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
        libncursesw5-dev libspice-protocol-dev libspice-server-dev libusb-1.0-0-dev \
        libusbredirparser-dev libcap-ng-dev libcap-dev libaio-dev python3-venv
      ;;
    centos)
      sudo dnf config-manager --set-enabled crb
      sudo dnf makecache
      sudo dnf install -y git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
        libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel bzip2 \
        nfs-utils libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
        libfdt-devel librados-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel
      ;;
    rhel)
      sudo dnf makecache
      sudo dnf install -y git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
        libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel bzip2 \
        nfs-utils libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
        libfdt-devel librados-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
            dh-autoreconf bridge-utils libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel \
            libnfs-devel libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
            libfdt-devel libu2f-server-devel libu2f-host-devel libglusterfs-devel librados-devel \
            spice-server-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel
          ;;
        *)
          sudo dnf makecache
          sudo dnf install -y git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
            dh-autoreconf bridge-utils libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel \
            libnfs-devel libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
            libfdt-devel libu2f-server-devel libu2f-host-devel libglusterfs-devel librados-devel \
            spice-server-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel
          ;;
        esac
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
    ./configure --disable-docs --target-list=x86_64-softmmu --enable-virtfs --disable-werror
    make -j "$(nproc)"
  )
}

check_qemu() {
  qemu_dir="$(realpath "${1}")"

  qemu_args=(
    -monitor stdio
    -nographic
    -serial none
  )

  if [ "${DISABLE_KVM_CHECK}" != "yes" ]; then
    qemu_args+=(
      -enable-kvm
      -netdev tap,id=net0,vhost=on,script=no,downscript=no -device e1000,netdev=net0
    )
  fi

  unshare --user --net --map-root-user \
    "${qemu_dir}/build/qemu-system-x86_64" "${qemu_args[@]}" <<< q
  [ -f "${qemu_dir}/build/qemu-img" ] || return 1
  [ -f "${qemu_dir}/build/contrib/ivshmem-server/ivshmem-server" ] || return 1

  if [ ! -f "${qemu_dir}/build/tools/virtiofsd/virtiofsd" ]; then
    [ -f "${FS_DAEMON_BIN}" ] || return 1
  fi

  return 0
}

get_config_qemu() {
  qemu_dir="$(realpath "${1}")"

  echo "QEMU_BIN='${qemu_dir}/build/qemu-system-x86_64'"
  echo "QEMU_IMG_BIN='${qemu_dir}/build/qemu-img'"
  echo "IVSHMEM_SERVER_BIN='${qemu_dir}/build/contrib/ivshmem-server/ivshmem-server'"
  [ -f "${FS_DAEMON_BIN}" ] || echo "FS_DAEMON_BIN='${qemu_dir}/build/tools/virtiofsd/virtiofsd'"
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
