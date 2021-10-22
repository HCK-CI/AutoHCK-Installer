#!/bin/bash

set -e

log () {
  echo -e "$*" >&2
}

log_info() {
  log '\033[0;32mINFO: ' "$*" '\033[0m'
}

log_warn() {
  log '\033[1;33mWARN: ' "$*" '\033[0m'
}

log_error() {
  log '\033[0;31mERROR: ' "$*" '\033[0m'
}

log_fatal () {
  log '\033[0;31mFATAL: ' "$*" '\033[0m'
  exit 1
}
