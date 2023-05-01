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
VIRTIOFSD_REF=v1.5.1
# VIRTIOFSD_DIR=

QEMU_GIT=https://github.com/qemu/qemu.git
QEMU_REF=v8.0.0
# QEMU_DIR=

TOOLSHCK_GIT=https://github.com/HCK-CI/toolsHCK.git
TOOLSHCK_REF=88fba7cd89fe9fe4aeded143f3b98df11238bc71
#TOOLSHCK_DIR=

HLK_SETUP_SCRIPTS_GIT=https://github.com/HCK-CI/HLK-Setup-Scripts.git
HLK_SETUP_SCRIPTS_REF=52bdfc4481ce24e87fd1236b74f38c076e215c96
# HLK_SETUP_SCRIPTS_DIR=

EXTRA_SOFTWARE_GIT=https://github.com/HCK-CI/extra-software.git
EXTRA_SOFTWARE_REF=bd64ba75f7ec7371b629ddc4017ca091812beecc
# EXTRA_SOFTWARE_DIR=

HLK_PLAYLISTS_GIT=https://github.com/HCK-CI/hlkplaylists.git
HLK_PLAYLISTS_REF=948e3da083ccb4713c7024fd6c334d28cddabf0a
# HLK_PLAYLISTS_DIR=

HCK_FILTERS_GIT=https://github.com/HCK-CI/hckfilters.git
HCK_FILTERS_REF=12f6b54cc2d8e788605e2f6abd38c44b5239a374
# HCK_FILTERS_DIR=

AUTOHCK_GIT=https://github.com/HCK-CI/AutoHCK.git
AUTOHCK_REF=v0.10.3
# AUTOHCK_DIR=
