#!/bin/bash

set -ex

# Need to propagate error in line 'bash | tee'
set -o pipefail

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

image_to_run="${1}"

declare -A test_image_list test_dist_list
test_image_list[centos:9]=quay.io/centos/centos:stream9
test_image_list[centos:10]=quay.io/centos/centos:stream10
test_image_list[fedora:34]=fedora:34
test_image_list[fedora:37]=fedora:37
test_image_list[fedora:39]=fedora:39
test_image_list[ubuntu:20]=ubuntu:20.04
test_image_list[ubuntu:22]=ubuntu:22.04

tee() { if test "$1" != "${1%/*}"; then mkdir -p ${1%/*}; fi &&
   command tee -a "$1"; }

run_for_image() {
    image="${1}"

    printf "TESTING: %s image %s\n" "${image}" "${test_image_list[$image]}"
    log_file="${work_dir}/logs/${image}.log"
    rm -f "${log_file}"
    bash "${work_dir}/create_run_script.sh" "$(cut -d':' -f1 <<<"${image}")" | tee "${log_file}"
    bash "${work_dir}/docker_run.sh" "${test_image_list[$image]}" | tee "${log_file}"
}

if [ -n "${image_to_run}" ]; then
    run_for_image "${image_to_run}"
else
    for image in "${!test_image_list[@]}"; do
        run_for_image "${image}"
    done
fi
