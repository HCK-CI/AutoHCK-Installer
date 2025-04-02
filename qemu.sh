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
        libusbredirparser-dev libcap-ng-dev libcap-dev libaio-dev python3-venv \
        python3-tomli
      ;;
    centos)
      sudo dnf config-manager --set-enabled crb
      sudo dnf makecache
      sudo dnf install -y git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
        libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel bzip2 \
        nfs-utils libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
        libfdt-devel librados-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel \
        python3-tomli
      ;;
    rhel)
      sudo dnf makecache
      sudo dnf install -y git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
        libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel bzip2 \
        nfs-utils libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
        libfdt-devel librados-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel \
        python3-tomli
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
            dh-autoreconf bridge-utils libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel \
            libnfs-devel libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
            libfdt-devel libu2f-server-devel libu2f-host-devel libglusterfs-devel librados-devel \
            spice-server-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel \
            python3-tomli
          ;;
        *)
          sudo dnf makecache
          sudo dnf install -y git gcc g++ make meson pkg-config zlib-devel glib2-devel pixman-devel libtool \
            dh-autoreconf bridge-utils libpng-devel libjpeg-devel SDL2-devel gtk3-devel libaio-devel \
            libnfs-devel libseccomp-devel libiscsi-devel libzstd-devel curl-devel keyutils-libs-devel \
            libfdt-devel libu2f-server-devel libu2f-host-devel libglusterfs-devel librados-devel \
            spice-server-devel libusb1-devel usbredir-devel libcap-ng-devel libattr-devel \
            python3-tomli
          ;;
        esac
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac
}

install_qemu_package() {
  log_info "Installing QEMU package"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      sudo apt-get update
      sudo apt-get install -y qemu-system
      ;;
    centos | rhel)
      sudo dnf makecache
      sudo dnf install -y qemu-kvm
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent qemu
          ;;
        *)
          sudo dnf makecache
          sudo dnf install -y qemu
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
    "${QEMU_BIN}" "${qemu_args[@]}" <<< q
  [ -f "${QEMU_IMG_BIN}" ] || return 1

  if [ -n "${IVSHMEM_SERVER_BIN}" ]; then
    [ -f "${IVSHMEM_SERVER_BIN}" ] || return 1
  fi

  [ -f "${FS_DAEMON_BIN}" ] || return 1

  return 0
}

get_config_qemu_repo() {
  qemu_dir="$(realpath "${1}")"

  echo "QEMU_BIN='${qemu_dir}/build/qemu-system-x86_64'"
  echo "QEMU_IMG_BIN='${qemu_dir}/build/qemu-img'"
  echo "IVSHMEM_SERVER_BIN='${qemu_dir}/build/contrib/ivshmem-server/ivshmem-server'"
  [ -f "${FS_DAEMON_BIN}" ] || echo "FS_DAEMON_BIN='${qemu_dir}/build/tools/virtiofsd/virtiofsd'"
}

get_config_qemu_package() {
  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu|fedora)
      QEMU_BIN='/usr/bin/qemu-system-x86_64'
      QEMU_IMG_BIN='/usr/bin/qemu-img'
      ;;
    centos|rhel)
      QEMU_BIN='/usr/libexec/qemu-kvm'
      QEMU_IMG_BIN='/usr/bin/qemu-img'
      ;;
    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please compile QEMU manually."
      ;;
  esac

  echo "QEMU_BIN='${QEMU_BIN}'"
  echo "QEMU_IMG_BIN='${QEMU_IMG_BIN}'"
}

install_vm_deps() {
  log_info "Installing QEMU VM dependencies"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      sudo apt update
      sudo apt -y install ovmf swtpm swtpm-tools
      ;;
    centos)
      sudo dnf config-manager --set-enabled crb
      sudo dnf makecache
      sudo dnf -y install edk2-ovmf swtpm swtpm-tools
      ;;
    rhel)
      sudo dnf makecache
      sudo dnf -y install edk2-ovmf swtpm swtpm-tools
      ;;
    fedora)
      case "$( get_distribution_variant )" in
        silverblue)
          rpm-ostree install -A --allow-inactive --idempotent edk2-ovmf swtpm swtpm-tools
          ;;
        *)
          sudo dnf makecache
          sudo dnf -y install edk2-ovmf swtpm swtpm-tools
          ;;
        esac
      ;;

    *)
      log_fatal "Distributive '$lsb_dist' is unsupported. Please install OVMF, SWTPM manually."
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

post_clone_QEMU() {
  log_info "QEMU repository post clone"

  qemu_dir="$(realpath "${1}")"

  install_deps_qemu
  compile_qemu "${qemu_dir}"

  log "QEMU binary compiled"
}

process_QEMU() {
  log_info "QEMU dependency custom processing"

  qemu_package="${2}"

  install_vm_deps
  get_fw_config >>"${bootstrap}"

  if [ "x${qemu_package}" == "x" ]; then
    qemu_dir="$(realpath "${1}")"
    get_config_qemu_repo "${qemu_dir}" >>"${bootstrap}"
  else
    install_qemu_package
    get_config_qemu_package >>"${bootstrap}"
  fi

  source "${bootstrap}"

  if ! check_qemu "${qemu_dir}"; then
    log_fatal "Can't find QEMU binary"
  fi

  echo >>"${bootstrap}"
}
