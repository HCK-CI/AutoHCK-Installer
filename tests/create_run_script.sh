#!/bin/bash

set -e

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
test_script="${work_dir}/run.sh"

source "${work_dir}/../logger.sh"

echo '#!/bin/bash' > "${test_script}"
echo set -e >> "${test_script}"
echo export REPOS_DIR=/root/HCK-CI/repos >> "${test_script}"
echo export ISO_PATH=/root/HCK-CI/iso >> "${test_script}"
echo export IMAGES_PATH=/root/HCK-CI/images >> "${test_script}"
echo export WORKSPACE_PATH=/root/HCK-CI/workspace >> "${test_script}"

# we don't need KVM to test deployment
# so just mask that we run in docker
echo export DISABLE_KVM_CHECK=yes >> "${test_script}"

test_dist="${1}"
test_dist_variant="${2}"

case "${test_dist}" in
  ubuntu)
    echo apt update >> "${test_script}"
    echo DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends tzdata >> "${test_script}"
    echo apt install -y git jq sudo gnupg2 >> "${test_script}"
    ;;
  centos)
    echo dnf makecache >> "${test_script}"
    echo dnf install -y git jq which sudo dnf-plugins-core procps >> "${test_script}"
    echo dnf config-manager --set-enabled crb >> "${test_script}"
    ;;
  fedora)
    case "${test_dist_variant}" in
      silverblue)
        log_fatal "Distributive '$lsb_dist/$test_dist_variant' is unsupported for test run."
        ;;
      *)
        echo dnf makecache
        echo dnf install -y git jq which procps >> "${test_script}"
        ;;
      esac
    ;;
  *)
    log_fatal "Distributive '$lsb_dist' is unsupported for test run."
    ;;
esac


echo bash /src/install.sh --silent >> "${test_script}"

echo xorriso -as mkisofs \
  -iso-level 4 -J -l -D -N \
  -joliet-long -relaxed-filenames -V "INSTALLER" \
  -old-exclude Kits \
  '"${REPOS_DIR}/HLK-Setup-Scripts.git"' \
  '-o "${WORKSPACE_PATH}/scripts.iso"' >> "${test_script}"
