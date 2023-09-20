#!/bin/bash

DEPENDENCIES=(
    VIRTIOFSD
    QEMU
    TOOLSHCK
    HLK_SETUP_SCRIPTS
    EXTRA_SOFTWARE
    HLK_PLAYLISTS
    HCK_FILTERS
    AUTOHCK
)

VIRTIOFSD_GIT=https://gitlab.com/virtio-fs/virtiofsd.git
VIRTIOFSD_REF=v1.6.1
# VIRTIOFSD_DIR=

QEMU_GIT=https://github.com/qemu/qemu.git
QEMU_REF=v8.1.0
# QEMU_DIR=

TOOLSHCK_GIT=https://github.com/HCK-CI/toolsHCK.git
TOOLSHCK_REF=88fba7cd89fe9fe4aeded143f3b98df11238bc71
#TOOLSHCK_DIR=

HLK_SETUP_SCRIPTS_GIT=https://github.com/HCK-CI/HLK-Setup-Scripts.git
HLK_SETUP_SCRIPTS_REF=37360d2648159d22abb379bd2af1e9f0af6dfb0f
# HLK_SETUP_SCRIPTS_DIR=

EXTRA_SOFTWARE_GIT=https://github.com/HCK-CI/extra-software.git
EXTRA_SOFTWARE_REF=e89497d1775b5afa044a42bf82af197d9608a9f0
# EXTRA_SOFTWARE_DIR=

HLK_PLAYLISTS_GIT=https://github.com/HCK-CI/hlkplaylists.git
HLK_PLAYLISTS_REF=8888fb18c722a00effc4a04cbc6f018ac8290fde
# HLK_PLAYLISTS_DIR=

HCK_FILTERS_GIT=https://github.com/HCK-CI/hckfilters.git
HCK_FILTERS_REF=6bf444d85d4f6cfb250fe5582b150b82c406a9fa
# HCK_FILTERS_DIR=

AUTOHCK_GIT=https://github.com/HCK-CI/AutoHCK.git
AUTOHCK_REF=v0.11.2
# AUTOHCK_DIR=
