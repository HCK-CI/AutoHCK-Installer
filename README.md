# AutoHCK Installer

This repository contains scripts to deploy HCK-CI solution at local server.

## Supported OS

Installation process has been tested at the following OSes:

1. Ubuntu 20.04
2. Fedora 32, 35

## Pre-requirements

Install latest version of the following tools:

1. docker - to run DHCP server tests

## Docker pre-configuration (optional)

Docker will be used to prepare images for DHCP server testing.
It will pull all images automatically. But if you need to [increase rate limits](https://www.docker.com/increase-rate-limits)
at you system, then do this before installation. Use `docker login` command for this.

## Installation

To install HCK-CI solution run `bash install.sh` as a root.

To move some repository to custom path, export the following variables:
  - QEMU_DIR
  - DHCP_DIR
  - TOOLSHCK_DIR
  - HLK_SETUP_SCRIPTS_DIR
  - EXTRA_SOFTWARE_DIR
  - HLK_PLAYLISTS_DIR
  - HCK_FILTERS_DIR
  - AUTOHCK_DIR

```
export REPOS_DIR='/root/HCK-CI/repos'
export AUTOHCK_DIR='/root/AutoHCK'
export HLK_SETUP_SCRIPTS_DIR='/data/HCK-CI/HLK-Setup-Scripts'
bash install.sh
```
