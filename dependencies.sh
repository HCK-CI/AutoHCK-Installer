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
HLK_SETUP_SCRIPTS_REF=26b9e71d7411ef4a57ffb3dc36af4b0c53a4fac0
# HLK_SETUP_SCRIPTS_DIR=

EXTRA_SOFTWARE_GIT=https://github.com/HCK-CI/extra-software.git
EXTRA_SOFTWARE_REF=21452ce2bfecc1787cdbd7a729f1ce7b90499d63
# EXTRA_SOFTWARE_DIR=

HLK_PLAYLISTS_GIT=https://github.com/HCK-CI/hlkplaylists.git
HLK_PLAYLISTS_REF=8888fb18c722a00effc4a04cbc6f018ac8290fde
# HLK_PLAYLISTS_DIR=

HCK_FILTERS_GIT=https://github.com/HCK-CI/hckfilters.git
HCK_FILTERS_REF=f3ec4b294a90642ba82ea94c7462245246b11401
# HCK_FILTERS_DIR=

AUTOHCK_GIT=https://github.com/HCK-CI/AutoHCK.git
AUTOHCK_REF=v0.12.1
# AUTOHCK_DIR=
