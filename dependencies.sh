#!/bin/bash

DEPENDENCIES=(
    QEMU
    DHCP
    TOOLSHCK
    HLK_SETUP_SCRIPTS
    EXTRA_SOFTWARE
    HLK_PLAYLISTS
    HCK_FILTERS
    AUTOHCK
)

QEMU_GIT=https://github.com/qemu/qemu.git
QEMU_REF=v6.1.0
# QEMU_DIR=

DHCP_GIT=https://github.com/HCK-CI/DHCPServerSetup.git
DHCP_REF=52cac804d8dabb43014173888328bf466741783a
# DHCP_DIR=

TOOLSHCK_GIT=https://github.com/HCK-CI/toolsHCK.git
TOOLSHCK_REF=88fba7cd89fe9fe4aeded143f3b98df11238bc71
#TOOLSHCK_DIR=

HLK_SETUP_SCRIPTS_GIT=https://github.com/HCK-CI/HLK-Setup-Scripts.git
HLK_SETUP_SCRIPTS_REF=b2c95016eb45099975f2ab93f97ecfd8497353a4
# HLK_SETUP_SCRIPTS_DIR=

EXTRA_SOFTWARE_GIT=https://github.com/HCK-CI/extra-software.git
EXTRA_SOFTWARE_REF=69a88f17da75deb1c840aae3e7f82f8d503c6652
# EXTRA_SOFTWARE_DIR=

HLK_PLAYLISTS_GIT=https://github.com/HCK-CI/hlkplaylists.git
HLK_PLAYLISTS_REF=1f708a0ff8f28ce5052e812a620633f17ca05427
# HLK_PLAYLISTS_DIR=

HCK_FILTERS_GIT=https://github.com/HCK-CI/hckfilters.git
HCK_FILTERS_REF=9a00f68cca9d46f75c3d75046687c10714758b5a
# HCK_FILTERS_DIR=

AUTOHCK_GIT=https://github.com/HCK-CI/AutoHCK.git
AUTOHCK_REF=52ad6c0c03d2425ba09316ae2e27be98ebbdc079
# AUTOHCK_DIR=
